import Mathlib.Algebra.Ring.Basic
import Mathlib.Tactic.Ring

variable {R : Type*} [CommRing R]

def KeyGen (a s e : R) : (R * R) * R :=
  let b := a * s + e
  ((a, b), s)

def Encrypt (pk : R * R) (r e1 e2 M : R) : R * R :=
  let (a, b) := pk
  let u := a * r + e1
  let v := b * r + e2 + M
  (u, v)

def Decrypt (sk : R) (c : R * R) : R :=
  let (u, v) := c
  v - u * sk

theorem clh_max_correctness (a s e r e1 e2 M : R) :
  let (pk, sk) := KeyGen a s e
  let c := Encrypt pk r e1 e2 M
  Decrypt sk c = M + (e * r + e2 - e1 * s) := by
  dsimp [KeyGen, Encrypt, Decrypt]
  ring
