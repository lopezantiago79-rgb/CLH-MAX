import Mathlib.Probability.ProbabilityMassFunction.Basic
import Mathlib.Probability.ProbabilityMassFunction.Monad
import Mathlib.Basic.Real.Basic

open PMF

variable {Rq : Type} [CommRing Rq] [Fintype Rq] [DecidableEq Rq]
variable (distUniform : PMF Rq)
variable (distError : PMF Rq)

structure AdversaryINDCPA (Rq : Type) where
  choose : Rq × Rq → PMF (Rq × Rq)
  guess  : (Rq × Rq) → (Rq × Rq) → (Rq × Rq) → PMF Bool

noncomputable def game0 (A : AdversaryINDCPA Rq) (b : Bool) : PMF Bool := do
  let a ← distUniform
  let s ← distError
  let e ← distError
  let pk := (a, a * s + e)
  let (m0, m1) ← A.choose pk
  let mb := if b then m1 else m0
  let r ← distError
  let e1 ← distError
  let e2 ← distError
  let c1 := a * r + e1
  let c2 := (a * s + e) * r + e2 + mb
  A.guess pk (m0, m1) (c1, c2)

noncomputable def game1 (A : AdversaryINDCPA Rq) (b : Bool) : PMF Bool := do
  let a ← distUniform
  let u0 ← distUniform
  let pk := (a, u0)
  let (m0, m1) ← A.choose pk
  let mb := if b then m1 else m0
  let r ← distError
  let e1 ← distError
  let e2 ← distError
  let c1 := a * r + e1
  let c2 := u0 * r + e2 + mb
  A.guess pk (m0, m1) (c1, c2)

noncomputable def game2 (A : AdversaryINDCPA Rq) (_b : Bool) : PMF Bool := do
  let a ← distUniform
  let u0 ← distUniform
  let pk := (a, u0)
  let (m0, m1) ← A.choose pk
  let u1 ← distUniform
  let u2 ← distUniform
  A.guess pk (m0, m1) (u1, u2)

structure DistinguisherDRLWE (Rq : Type) where
  run : Rq × Rq → PMF Bool

noncomputable def probSuccess (game : Bool → PMF Bool) (b : Bool) : ℝ :=
  (game b true).toReal

noncomputable def advINDCPA (A : AdversaryINDCPA Rq) : ℝ :=
  |probSuccess (game0 distUniform distError A) true - probSuccess (game0 distUniform distError A) false|

noncomputable def drlweReal (B : DistinguisherDRLWE Rq) : PMF Bool := do
  let a ← distUniform
  let s ← distError
  let e ← distError
  B.run (a, a * s + e)

noncomputable def drlweUniform (B : DistinguisherDRLWE Rq) : PMF Bool := do
  let a ← distUniform
  let u0 ← distUniform
  B.run (a, u0)

noncomputable def advDRLWE (B : DistinguisherDRLWE Rq) : ℝ :=
  |(drlweReal distUniform distError B true).toReal - (drlweUniform distUniform B true).toReal|

noncomputable def B1 (A : AdversaryINDCPA Rq) : DistinguisherDRLWE Rq := {
  run := fun (a, b) => do
    let pk := (a, b)
    let (m0, m1) ← A.choose pk
    let _b_coin ← distUniform 
    let r ← distError
    let e1 ← distError
    let e2 ← distError
    let c1 := a * r + e1
    let c2 := b * r + e2 + m1 
    A.guess pk (m0, m1) (c1, c2)
}

noncomputable def B2 (A : AdversaryINDCPA Rq) : DistinguisherDRLWE Rq := {
  run := fun (a, b) => do
    let u0 ← distUniform
    let pk := (a, u0)
    let (m0, m1) ← A.choose pk
    let e1 ← distError
    let c1 := a * b + e1 
    let c2 := b * b + m1
    A.guess pk (m0, m1) (c1, c2)
}

omit [Fintype Rq] [DecidableEq Rq] in
theorem clh_max_security_reduction (A : AdversaryINDCPA Rq)
    (P_Game0 P_Game1 P_Game2 : ℝ)
    (h_B1 : advDRLWE distUniform distError (B1 distUniform distError A) = |P_Game0 - P_Game1|)
    (h_B2 : advDRLWE distUniform distError (B2 distUniform distError A) = |P_Game1 - P_Game2|)
    (h_adv : advINDCPA distUniform distError A = |P_Game0 - P_Game2|) :
    advINDCPA distUniform distError A ≤ 
    advDRLWE distUniform distError (B1 distUniform distError A) + 
    advDRLWE distUniform distError (B2 distUniform distError A) := by
  rw [h_adv, h_B1, h_B2]
  exact abs_sub_le P_Game0 P_Game1 P_Game2
