-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright (C) 2026 Santiago López Heinzen
--
-- This file is part of CLH MAX KEM.
-- Licensed under the GNU Affero General Public License v3.0 or later.
-- See LICENSE in the repository root for the full license text.
-- <https://www.gnu.org/licenses/agpl-3.0.html>
--
-- Deposited on Zenodo: https://doi.org/10.5281/zenodo.22943292

/-
  CLH-MAX: game-hopping reduction for IND-CPA (Ring-LWE form, one module component, k = 1).

  What this file proves:  for ANY ring R, ANY distributions `unif`, `noise` on R (U is only
  assumed translation-invariant, which holds for every constant distribution, in particular
  the uniform one, see the last section) and ANY adversary A:

      advIND ≤ (eps1 true + eps2 true) + (eps1 false + eps2 false)

  where eps1 / eps2 are the advantages of two explicit distinguishers B1 / B2 against
  (Ring-)LWE with 1 resp. 2 samples.  This is the left-or-right form; the bit-guessing form
  of the paper's Theorem follows from it by the usual argument.

  What it does NOT do:
    * it does not assume or use any hardness axiom (the old `drlwe_hardness` is gone);
    * it does not formalise hardness of (M)LWE nor running times of B1, B2;
    * it treats k = 1 (a single ring element as secret); the module case k > 1 is analogous
      but is not formalised here.

  Sampling order: the challenger samples the encryption randomness (r, e1, e2) BEFORE the
  adversary's `choose` step. This is equivalent (it does not depend on `choose`) and avoids
  commuting binds in hop 1/2.

  Check after compiling:   #print axioms ClhMax.clh_max_indcpa
  Expected: only `propext`, `Classical.choice`, `Quot.sound`.
-/
import Mathlib

namespace ClhMax

noncomputable section

variable {R σ : Type} [CommRing R]

/-- Probability that a Bool-valued experiment outputs `true`. -/
def pr (p : PMF Bool) : ℝ := (p true).toReal

/-- Advantage of distinguishing the experiments `real.bind D` and `rand.bind D`. -/
def advDist {S : Type} (real rand : PMF S) (D : S → PMF Bool) : ℝ :=
  |pr (real.bind D) - pr (rand.bind D)|

/-- Adversary with state `σ`: `choose` gets the public key `(a, t)` and returns two
messages and a state; `guess` gets the state and the ciphertext `(c1, c2)`. -/
structure Adversary (R σ : Type) where
  choose : R × R → PMF (R × R × σ)
  guess : σ → R × R → PMF Bool

/-- The message selected by the challenge bit. -/
def msg {R σ : Type} (b : Bool) (x : R × R × σ) : R := if b then x.2.1 else x.1

/-! ### Sample distributions for the two hops -/

/-- Hop 1, real: `(a, a*s + e)`. -/
def S1real (unif noise : PMF R) : PMF (R × R) :=
  unif.bind fun a => noise.bind fun s => noise.bind fun e => PMF.pure (a, a * s + e)

/-- Hop 1, random: `(a, u)`. -/
def S1rand (unif : PMF R) : PMF (R × R) :=
  unif.bind fun a => unif.bind fun u => PMF.pure (a, u)

/-- Hop 2, real: `((a, t), (a*r + e1, t*r + e2))` (two LWE samples with secret `r`). -/
def S2real (unif noise : PMF R) : PMF ((R × R) × (R × R)) :=
  unif.bind fun a => unif.bind fun t =>
    noise.bind fun r => noise.bind fun e1 => noise.bind fun e2 =>
      PMF.pure ((a, t), (a * r + e1, t * r + e2))

/-- Hop 2, random: `((a, t), (w1, w2))` with `w1, w2` uniform. -/
def S2rand (unif : PMF R) : PMF ((R × R) × (R × R)) :=
  unif.bind fun a => unif.bind fun t => unif.bind fun w1 => unif.bind fun w2 =>
    PMF.pure ((a, t), (w1, w2))

/-! ### Distinguishers (simulators) -/

/-- B1 receives a public key `pk = (a, t)` and plays the encryption game with it. -/
def B1 (noise : PMF R) (A : Adversary R σ) (b : Bool) (pk : R × R) : PMF Bool :=
  noise.bind fun r => noise.bind fun e1 => noise.bind fun e2 =>
    (A.choose pk).bind fun x =>
      A.guess x.2.2 (pk.1 * r + e1, pk.2 * r + e2 + msg b x)

/-- B2 receives `((a, t), (w1, w2))`; it uses `(a, t)` as public key and answers the
challenge with `(w1, w2 + m_b)`. -/
def B2 (A : Adversary R σ) (b : Bool) (p : (R × R) × (R × R)) : PMF Bool :=
  (A.choose p.1).bind fun x => A.guess x.2.2 (p.2.1, p.2.2 + msg b x)

/-! ### Games -/

/-- Game 0: the real IND-CPA game with challenge bit `b`. -/
def G0 (unif noise : PMF R) (A : Adversary R σ) (b : Bool) : PMF Bool :=
  (S1real unif noise).bind (B1 noise A b)

/-- Game 1: public key `t` replaced by a uniform element. -/
def G1 (unif noise : PMF R) (A : Adversary R σ) (b : Bool) : PMF Bool :=
  (S1rand unif).bind (B1 noise A b)

/-- Game 2: ciphertext replaced by uniform elements. -/
def G2 (unif : PMF R) (A : Adversary R σ) (b : Bool) : PMF Bool :=
  (S2rand unif).bind (B2 A b)

def advIND (unif noise : PMF R) (A : Adversary R σ) : ℝ :=
  |pr (G0 unif noise A true) - pr (G0 unif noise A false)|

def eps1 (unif noise : PMF R) (A : Adversary R σ) (b : Bool) : ℝ :=
  advDist (S1real unif noise) (S1rand unif) (B1 noise A b)

def eps2 (unif noise : PMF R) (A : Adversary R σ) (b : Bool) : ℝ :=
  advDist (S2real unif noise) (S2rand unif) (B2 A b)

/-! ### Lemmas -/

/-- Game 1 is exactly "B2 on real LWE samples" (this is where the algebra of the ciphertext
`c1 = a*r + e1`, `c2 = t*r + e2 + m` matches the LWE sample `B*r + e` with `B = (a; t)`). -/
theorem G1_eq_S2real (unif noise : PMF R) (A : Adversary R σ) (b : Bool) :
    G1 unif noise A b = (S2real unif noise).bind (B2 A b) := by
  simp only [G1, S1rand, S2real, B1, B2, PMF.bind_bind, PMF.pure_bind]

/-- Translation invariance of `unif` lets us shift inside a `bind`. -/
theorem shift_bind {β : Type} (unif : PMF R)
    (hU : ∀ m : R, unif.bind (fun w => PMF.pure (w + m)) = unif)
    (g : R → PMF β) (m : R) :
    unif.bind (fun w => g (w + m)) = unif.bind g := by
  calc unif.bind (fun w => g (w + m))
      = unif.bind (fun w => (PMF.pure (w + m)).bind g) := by simp [PMF.pure_bind]
    _ = (unif.bind (fun w => PMF.pure (w + m))).bind g := by rw [PMF.bind_bind]
    _ = unif.bind g := by rw [hU m]

/-- One-time-pad step: shifting the sampled `w` by something that depends on a later-sampled
`x` does not change the experiment. -/
theorem indep_of_shift {X β : Type} (unif : PMF R)
    (hU : ∀ m : R, unif.bind (fun w => PMF.pure (w + m)) = unif)
    (C : PMF X) (g : X → R → PMF β) (ms : X → R) :
    unif.bind (fun w => C.bind fun x => g x (w + ms x))
      = unif.bind (fun w => C.bind fun x => g x w) := by
  calc unif.bind (fun w => C.bind fun x => g x (w + ms x))
      = C.bind (fun x => unif.bind fun w => g x (w + ms x)) :=
        PMF.bind_comm unif C (fun w x => g x (w + ms x))
    _ = C.bind (fun x => unif.bind fun w => g x w) := by
        congr 1
        funext x
        exact shift_bind unif hU (g x) (ms x)
    _ = unif.bind (fun w => C.bind fun x => g x w) :=
        (PMF.bind_comm unif C (fun w x => g x w)).symm

/-- Game 2 does not depend on the message: it equals an experiment where `w2` is not shifted. -/
theorem G2_eq_unshifted (unif : PMF R)
    (hU : ∀ m : R, unif.bind (fun w => PMF.pure (w + m)) = unif)
    (A : Adversary R σ) (b : Bool) :
    G2 unif A b =
      unif.bind fun a => unif.bind fun t => unif.bind fun w1 => unif.bind fun w2 =>
        (A.choose (a, t)).bind fun x => A.guess x.2.2 (w1, w2) := by
  simp only [G2, S2rand, B2, PMF.bind_bind, PMF.pure_bind]
  congr 1
  funext a
  congr 1
  funext t
  congr 1
  funext w1
  exact indep_of_shift unif hU (A.choose (a, t)) (fun x w => A.guess x.2.2 (w1, w)) (msg b)

theorem G2_indep (unif : PMF R)
    (hU : ∀ m : R, unif.bind (fun w => PMF.pure (w + m)) = unif)
    (A : Adversary R σ) :
    G2 unif A true = G2 unif A false := by
  rw [G2_eq_unshifted unif hU A true, G2_eq_unshifted unif hU A false]

/-! ### Main theorem -/

theorem clh_max_indcpa (unif noise : PMF R)
    (hU : ∀ m : R, unif.bind (fun w => PMF.pure (w + m)) = unif)
    (A : Adversary R σ) :
    advIND unif noise A ≤
      (eps1 unif noise A true + eps2 unif noise A true) +
      (eps1 unif noise A false + eps2 unif noise A false) := by
  have h1 : ∀ b, eps1 unif noise A b
      = |pr (G0 unif noise A b) - pr (G1 unif noise A b)| := fun b => rfl
  have h2 : ∀ b, eps2 unif noise A b
      = |pr (G1 unif noise A b) - pr (G2 unif A b)| := by
    intro b
    unfold eps2 advDist
    rw [G1_eq_S2real unif noise A b]
    rfl
  have e : pr (G2 unif A true) = pr (G2 unif A false) := by
    rw [G2_indep unif hU A]
  have t1 : |pr (G0 unif noise A true) - pr (G2 unif A true)|
      ≤ |pr (G0 unif noise A true) - pr (G1 unif noise A true)|
        + |pr (G1 unif noise A true) - pr (G2 unif A true)| := abs_sub_le _ _ _
  have t0 : |pr (G0 unif noise A false) - pr (G2 unif A false)|
      ≤ |pr (G0 unif noise A false) - pr (G1 unif noise A false)|
        + |pr (G1 unif noise A false) - pr (G2 unif A false)| := abs_sub_le _ _ _
  have t2 : |pr (G0 unif noise A true) - pr (G0 unif noise A false)|
      ≤ |pr (G0 unif noise A true) - pr (G2 unif A true)|
        + |pr (G2 unif A true) - pr (G0 unif noise A false)| := abs_sub_le _ _ _
  have t3 : |pr (G2 unif A true) - pr (G0 unif noise A false)|
      = |pr (G0 unif noise A false) - pr (G2 unif A false)| := by
    rw [e, abs_sub_comm]
  unfold advIND
  rw [h1 true, h1 false, h2 true, h2 false]
  linarith

/-! ### A constant (e.g. uniform) distribution is translation invariant -/

/-- On a finite additive group the uniform distribution is constant (`unif a = unif b`);
every constant PMF is invariant under translations. This avoids depending on a particular
Mathlib constructor of the uniform distribution (which has been renamed/deprecated). -/
theorem shift_invariant_of_const {S : Type} [AddCommGroup S] (unif : PMF S)
    (hc : ∀ a b, unif a = unif b) (m : S) :
    unif.bind (fun w => PMF.pure (w + m)) = unif := by
  ext x
  rw [PMF.bind_apply]
  simp only [PMF.pure_apply]
  rw [tsum_eq_single (x - m)]
  · have hx : x = x - m + m := by simp
    simp [hc (x - m) x]
  · intro w hw
    have hx : x ≠ w + m := by
      intro h
      apply hw
      rw [h]
      simp
    simp [hx]

/-- The theorem for any distribution `unif` that is constant, in particular the uniform
distribution on a finite ring. -/
theorem clh_max_indcpa_uniform (unif noise : PMF R) (hc : ∀ a b, unif a = unif b)
    (A : Adversary R σ) :
    advIND unif noise A ≤
      (eps1 unif noise A true + eps2 unif noise A true) +
      (eps1 unif noise A false + eps2 unif noise A false) :=
  clh_max_indcpa unif noise (fun m => shift_invariant_of_const unif hc m) A

end

#print axioms ClhMax.clh_max_indcpa

end ClhMax
