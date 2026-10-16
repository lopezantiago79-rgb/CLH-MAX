# CLH-MAX

A research proposal for a lattice-based key encapsulation mechanism (KEM) in the style of
Kyber/ML-KEM, using the prime cyclotomic ring `Z_q[X]/Φ_257(X)` instead of `Z_q[X]/(X^256+1)`.
For `q = 3329` the polynomial `Φ_257` is irreducible, so the ring is the field `F_{q^256}`.

**Status:** research proposal, not standardized, not implemented for production use.
No claim is made that CLH-MAX is more secure than ML-KEM.

Author: Santiago López Heinzen — lopezantiago79@gmail.com

## What is in this repository

- `main.tex` / `paper/` — the paper (version 2).
- `ClhMaxSecurity.lean` — Lean 4 / Mathlib proof of the game-hopping reduction
  (see below for exactly what it proves).
- `scripts/dfp.py` — exact decryption-failure probability computation.
- `scripts/estimate_clh_max.py` — lattice-estimator runs for CLH-MAX and ML-KEM
  (same call, same cost model).
- `results/` — raw lattice-estimator output.
- `ERRATA.md` — corrections relative to version 1. **Version 2 supersedes version 1.**

## What the Lean file proves (and what it does not)

It proves, for any ring `R`, any distributions `unif` (translation-invariant, e.g. uniform)
and `noise`, and any adversary `A`:

`advIND ≤ (eps1 true + eps2 true) + (eps1 false + eps2 false)`

where `eps1`, `eps2` are the advantages of two explicit distinguishers against (Ring-)LWE
with one and two samples. It uses no hardness axiom and no `sorry`; `#print axioms` reports
only `propext`, `Classical.choice`, `Quot.sound`.

It does **not** formalise hardness of (M)LWE, running times, or the module case `k > 1`
(only `k = 1` is formalised).

Built with Lean `v4.35.0` and Mathlib `v4.35.0`:

```
lake exe cache get
lake build
```

## Main results (see the paper for details)

- IND-CPA security reduces to two decision-MLWE instances (paper proof; Lean for `k = 1`).
- Decryption failure probability (no compression, `q = 3329`, `η = 2`):
  `k = 2`: 2^-231, `k = 3`: 2^-156, `k = 4`: 2^-117 — the `k = 4` set does **not** reach 2^-128.
- Generic MLWE estimates (lattice-estimator): identical to ML-KEM-768/1024 for `k = 3, 4`
  (same `(n, q, noise)`), and about 7 bits lower than ML-KEM-512 for `k = 2` with `η = 2`.
- No negacyclic NTT at `q = 3329`; no performance claim is made.

## Open problems

Parameter sets meeting both `δ < 2^-128` and ML-KEM-level security at `k = 2, 4`;
estimation of the message-recovery instance; efficient implementation; algebraic
consequences of the field structure of the ring.

## License

This repository is dual-licensed:

- **Code** (Lean files, scripts): GNU Affero General Public License v3.0 (AGPL-3.0).
  See [`LICENSE`](LICENSE).
- **Paper** (`main.tex` and the PDF): Creative Commons Attribution 4.0 International
  (CC BY 4.0). See [`LICENSE-paper.md`](LICENSE-paper.md).

## How to cite

Santiago López Heinzen, *CLH-MAX: A Lattice-Based KEM Proposal over the Prime Cyclotomic
Ring Z_q[X]/Φ_257(X)*, 2026. Zenodo: https://doi.org/10.5281/zenodo.22943292
(the DOI will be updated to the version 2 record).
