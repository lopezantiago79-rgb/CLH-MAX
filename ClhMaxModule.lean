/-
  CLH-MAX: game-hopping reduction for IND-CPA, MODULE rank k (arbitrary k).

  Same argument as ClhMaxSecurity.lean (k = 1), now with public key (M, t), M a k x k matrix and
  t a vector of length k over a commutative ring R:

      t  = M s + e                      (secret s, error e : Fin k -> R)
      u  = M^T r + e1                   (r, e1 : Fin k -> R)
      v  = <t, r> + e2 + m              (e2 : R, m : R)

  Statement (left-or-right form), for ANY setup D (distributions) with `uR` translation-invariant
  and ANY adversary A:

      advIND D A <= (eps1 true + eps2 true) + (eps1 false + eps2 false)

  where eps1 is the advantage of a distinguisher against LWE with k samples (matrix M, vector t)
  and eps2 the advantage of a distinguisher against LWE with k+1 samples (rows (M^T ; t^T),
  secret r), exactly as in the paper's Theorem (bit-guessing form: the two left-or-right terms per
  hop are replaced by one).

  It does NOT formalise hardness of (M)LWE, running times of the distinguishers, or the
  Fujisaki-Okamoto transform.  No hardness axiom, no `sorry`.
  Matrices are plain functions `Fin k -> Fin k -> R`, products are written out with `Finset.sum`,
  so no Matrix API names are needed.

  Check after compiling:   #print axioms ClhMaxModule.clh_max_indcpa_module
  Expected: only `propext`, `Classical.choice`, `Quot.sound`.
-/
import Mathlib

namespace ClhMaxModule

noncomputable section

variable {R σ : Type} [CommRing R] {k : ℕ}

/-- Probability that a Bool-valued experiment outputs `true`. -/
def pr (p : PMF Bool) : ℝ := (p true).toReal

/-- Advantage of distinguishing `real.bind D` from `rand.bind D`. -/
def advDist {S : Type} (real rand : PMF S) (D : S → PMF Bool) : ℝ :=
  |pr (real.bind D) - pr (rand.bind D)|

/-- Matrix-vector product `M x`. -/
def mulV (M : Fin k → Fin k → R) (x : Fin k → R) : Fin k → R :=
  fun i => Finset.univ.sum fun j => M i j * x j

/-- Transposed product `M^T x`. -/
def mulVT (M : Fin k → Fin k → R) (x : Fin k → R) : Fin k → R :=
  fun j => Finset.univ.sum fun i => M i j * x i

/-- Dot product. -/
def dot (x y : Fin k → R) : R := Finset.univ.sum fun i => x i * y i

/-- The distributions used by the scheme: `uA` for the matrix, `uV` for uniform vectors,
`uR` for uniform ring elements, `nV`/`nR` for noise vectors / noise elements. -/
structure Setup (R : Type) (k : ℕ) where
  uA : PMF (Fin k → Fin k → R)
  uV : PMF (Fin k → R)
  uR : PMF R
  nV : PMF (Fin k → R)
  nR : PMF R

/-- Adversary with state `σ`: `choose` gets `(M, t)` and returns two messages and a state;
`guess` gets the state and the ciphertext `(u, v)`. -/
structure Adversary (R : Type) (k : ℕ) (σ : Type) where
  choose : (Fin k → Fin k → R) × (Fin k → R) → PMF (R × R × σ)
  guess : σ → (Fin k → R) × R → PMF Bool

/-- The message selected by the challenge bit. -/
def msg {R σ : Type} (b : Bool) (x : R × R × σ) : R := if b then x.2.1 else x.1

/-! ### Sample distributions for the two hops -/

/-- Hop 1, real: `(M, M s + e)`. -/
def S1real (D : Setup R k) : PMF ((Fin k → Fin k → R) × (Fin k → R)) :=
  D.uA.bind fun M => D.nV.bind fun s => D.nV.bind fun e => PMF.pure (M, mulV M s + e)

/-- Hop 1, random: `(M, t)` with `t` uniform. -/
def S1rand (D : Setup R k) : PMF ((Fin k → Fin k → R) × (Fin k → R)) :=
  D.uA.bind fun M => D.uV.bind fun t => PMF.pure (M, t)

/-- Hop 2, real: `((M, t), (M^T r + e1, <t, r> + e2))`  (k+1 LWE samples with secret `r`). -/
def S2real (D : Setup R k) :
    PMF (((Fin k → Fin k → R) × (Fin k → R)) × ((Fin k → R) × R)) :=
  D.uA.bind fun M => D.uV.bind fun t =>
    D.nV.bind fun r => D.nV.bind fun e1 => D.nR.bind fun e2 =>
      PMF.pure ((M, t), (mulVT M r + e1, dot t r + e2))

/-- Hop 2, random: `((M, t), (w1, w2))` with `w1`, `w2` uniform. -/
def S2rand (D : Setup R k) :
    PMF (((Fin k → Fin k → R) × (Fin k → R)) × ((Fin k → R) × R)) :=
  D.uA.bind fun M => D.uV.bind fun t => D.uV.bind fun w1 => D.uR.bind fun w2 =>
    PMF.pure ((M, t), (w1, w2))

/-! ### Distinguishers (simulators) -/

/-- B1 receives a public key `pk = (M, t)` and plays the encryption game with it. -/
def B1 (D : Setup R k) (A : Adversary R k σ) (b : Bool)
    (pk : (Fin k → Fin k → R) × (Fin k → R)) : PMF Bool :=
  D.nV.bind fun r => D.nV.bind fun e1 => D.nR.bind fun e2 =>
    (A.choose pk).bind fun x =>
      A.guess x.2.2 (mulVT pk.1 r + e1, dot pk.2 r + e2 + msg b x)

/-- B2 receives `((M, t), (w1, w2))`; it uses `(M, t)` as public key and answers the
challenge with `(w1, w2 + m_b)`. -/
def B2 (A : Adversary R k σ) (b : Bool)
    (p : ((Fin k → Fin k → R) × (Fin k → R)) × ((Fin k → R) × R)) : PMF Bool :=
  (A.choose p.1).bind fun x => A.guess x.2.2 (p.2.1, p.2.2 + msg b x)

/-! ### Games -/

def G0 (D : Setup R k) (A : Adversary R k σ) (b : Bool) : PMF Bool :=
  (S1real D).bind (B1 D A b)

def G1 (D : Setup R k) (A : Adversary R k σ) (b : Bool) : PMF Bool :=
  (S1rand D).bind (B1 D A b)

def G2 (D : Setup R k) (A : Adversary R k σ) (b : Bool) : PMF Bool :=
  (S2rand D).bind (B2 A b)

def advIND (D : Setup R k) (A : Adversary R k σ) : ℝ :=
  |pr (G0 D A true) - pr (G0 D A false)|

def eps1 (D : Setup R k) (A : Adversary R k σ) (b : Bool) : ℝ :=
  advDist (S1real D) (S1rand D) (B1 D A b)

def eps2 (D : Setup R k) (A : Adversary R k σ) (b : Bool) : ℝ :=
  advDist (S2real D) (S2rand D) (B2 A b)

/-! ### Lemmas -/

/-- Game 1 is exactly "B2 on real LWE samples": the ciphertext
`(M^T r + e1, <t, r> + e2 + m)` is the LWE sample with matrix `(M^T ; t^T)` and secret `r`. -/
theorem G1_eq_S2real (D : Setup R k) (A : Adversary R k σ) (b : Bool) :
    G1 D A b = (S2real D).bind (B2 A b) := by
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

/-- Game 2 does not depend on the message. -/
theorem G2_eq_unshifted (D : Setup R k)
    (hU : ∀ m : R, D.uR.bind (fun w => PMF.pure (w + m)) = D.uR)
    (A : Adversary R k σ) (b : Bool) :
    G2 D A b =
      D.uA.bind fun M => D.uV.bind fun t => D.uV.bind fun w1 => D.uR.bind fun w2 =>
        (A.choose (M, t)).bind fun x => A.guess x.2.2 (w1, w2) := by
  simp only [G2, S2rand, B2, PMF.bind_bind, PMF.pure_bind]
  congr 1
  funext M
  congr 1
  funext t
  congr 1
  funext w1
  exact indep_of_shift D.uR hU (A.choose (M, t)) (fun x w => A.guess x.2.2 (w1, w)) (msg b)

theorem G2_indep (D : Setup R k)
    (hU : ∀ m : R, D.uR.bind (fun w => PMF.pure (w + m)) = D.uR)
    (A : Adversary R k σ) :
    G2 D A true = G2 D A false := by
  rw [G2_eq_unshifted D hU A true, G2_eq_unshifted D hU A false]

/-! ### Main theorem (module rank k) -/

theorem clh_max_indcpa_module (D : Setup R k)
    (hU : ∀ m : R, D.uR.bind (fun w => PMF.pure (w + m)) = D.uR)
    (A : Adversary R k σ) :
    advIND D A ≤
      (eps1 D A true + eps2 D A true) + (eps1 D A false + eps2 D A false) := by
  have h1 : ∀ b, eps1 D A b = |pr (G0 D A b) - pr (G1 D A b)| := fun b => rfl
  have h2 : ∀ b, eps2 D A b = |pr (G1 D A b) - pr (G2 D A b)| := by
    intro b
    unfold eps2 advDist
    rw [G1_eq_S2real D A b]
    rfl
  have e : pr (G2 D A true) = pr (G2 D A false) := by
    rw [G2_indep D hU A]
  have t1 : |pr (G0 D A true) - pr (G2 D A true)|
      ≤ |pr (G0 D A true) - pr (G1 D A true)|
        + |pr (G1 D A true) - pr (G2 D A true)| := abs_sub_le _ _ _
  have t0 : |pr (G0 D A false) - pr (G2 D A false)|
      ≤ |pr (G0 D A false) - pr (G1 D A false)|
        + |pr (G1 D A false) - pr (G2 D A false)| := abs_sub_le _ _ _
  have t2 : |pr (G0 D A true) - pr (G0 D A false)|
      ≤ |pr (G0 D A true) - pr (G2 D A true)|
        + |pr (G2 D A true) - pr (G0 D A false)| := abs_sub_le _ _ _
  have t3 : |pr (G2 D A true) - pr (G0 D A false)|
      = |pr (G0 D A false) - pr (G2 D A false)| := by
    rw [e, abs_sub_comm]
  unfold advIND
  rw [h1 true, h1 false, h2 true, h2 false]
  linarith

/-! ### A constant (e.g. uniform) distribution is translation invariant -/

theorem shift_invariant_of_const {S : Type} [AddCommGroup S] (unif : PMF S)
    (hc : ∀ a b, unif a = unif b) (m : S) :
    unif.bind (fun w => PMF.pure (w + m)) = unif := by
  ext x
  rw [PMF.bind_apply]
  simp only [PMF.pure_apply]
  rw [tsum_eq_single (x - m)]
  · simp [hc (x - m) x]
  · intro w hw
    have hx : x ≠ w + m := by
      intro h
      apply hw
      rw [h]
      simp
    simp [hx]

/-- The module-rank-k theorem when `uR` is any constant distribution, in particular the uniform
distribution on a finite ring. -/
theorem clh_max_indcpa_module_uniform (D : Setup R k) (hc : ∀ a b, D.uR a = D.uR b)
    (A : Adversary R k σ) :
    advIND D A ≤
      (eps1 D A true + eps2 D A true) + (eps1 D A false + eps2 D A false) :=
  clh_max_indcpa_module D (fun m => shift_invariant_of_const D.uR hc m) A

end

#print axioms ClhMaxModule.clh_max_indcpa_module

end ClhMaxModule
