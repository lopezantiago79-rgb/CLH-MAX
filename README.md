# CLH-MAX

A research proposal for a lattice-based key encapsulation mechanism (KEM) in the style of
Kyber/ML-KEM, using the prime cyclotomic ring `Z_q[X]/Φ_257(X)` instead of `Z_q[X]/(X^256+1)`.
For primes `q` that are primitive roots modulo 257 the polynomial `Φ_257` is irreducible, so the
ring is the field `F_{q^256}`.

**Status:** unrefereed technical note. Research proposal, not standardized, not for production use.
No claim is made that CLH-MAX is more secure than ML-KEM.

Author: Santiago López Heinzen — lopezantiago79@gmail.com

## Repository contents

- `main.tex`, `paper/CLH_MAX.pdf` — the paper (version 2.0.1).
- `ClhMaxSecurity.lean`, `lakefile.lean`, `lean-toolchain` — Lean 4 / Mathlib proof of the
  game-hopping reduction (see below for exactly what it proves).
- `scripts/dfp.py` — exact decryption-failure probability computation.
- `scripts/estimate_clh_max.py` — first lattice-estimator runs (version 2.0.0 parameters).
- `scripts/estimate_candidates.py` — estimator runs for candidate moduli.
- `scripts/estimate_message_recovery.py` — estimator runs for the message-recovery instances.
- `results/` — raw, unmodified lattice-estimator output.
- `ERRATA.md` — corrections relative to earlier versions. **Later versions supersede earlier ones.**

## Parameter sets

All sets use centered binomial noise `η = 2`, no ciphertext compression.

| Set | k | n = 256k | q | pk (B) | ct (B) | sk (B) | log2 δ |
|---|---|---|---|---|---|---|---|
| CLH-MAX-512 | 2 | 512 | 2531 | 800 | 1152 | 1632 | -133.5 |
| CLH-MAX-768 | 3 | 768 | 3329 | 1184 | 1536 | 2400 | -155.9 |
| CLH-MAX-1024 | 4 | 1024 | 3557 | 1568 | 1920 | 3168 | -133.7 |

`δ` is computed exactly under the usual independence heuristic (see the paper).

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
- With the ML-KEM modulus `q = 3329` the rank-4 set has `δ ≈ 2^-117` and does not reach `2^-128`;
  choosing the modulus per rank (`q = 2531, 3329, 3557`) gives `δ ≤ 2^-133` for all three sets.
- Generic MLWE estimates (lattice-estimator, key and message recovery, same call for CLH-MAX and
  ML-KEM): identical to ML-KEM-768 for `k = 3`; `+0.2` bits vs. the weakest ML-KEM-512 instance for
  `k = 2`; `-1.9` bits vs. ML-KEM-1024 for `k = 4`. The ring itself plays no role in these estimates.
- No NTT is available for any of the three moduli; no performance claim is made.

## Reproducing the numbers

```
python3 scripts/dfp.py
```

The estimator scripts must be run inside a checkout of the
[lattice-estimator](https://github.com/malb/lattice-estimator); raw outputs are in `results/`.

## Open problems

A rigorous bound on `δ` and the effect of ciphertext compression; narrowing the residual gap at
`k = 4`; efficient implementation without an NTT; algebraic consequences of the field structure of
the ring; a machine-checked proof for `k > 1`.

## License

This repository is dual-licensed:

- **Code** (Lean files, scripts): GNU Affero General Public License v3.0 (AGPL-3.0).
  See [`LICENSE`](LICENSE).
- **Paper** (`main.tex` and the PDF): Creative Commons Attribution 4.0 International
  (CC BY 4.0). See [`LICENSE-paper.md`](LICENSE-paper.md).

## How to cite

Santiago López Heinzen, *CLH-MAX: A Lattice-Based KEM Proposal over the Prime Cyclotomic
Ring Z_q[X]/Φ_257(X)*, version 2.0.1, 2026.
Zenodo: https://doi.org/10.5281/zenodo.23460069

All versions (always resolves to the latest): https://doi.org/10.5281/zenodo.22883946

Earlier Zenodo versions (v1 to 1.6) contain the previous version of this work, whose claims
are withdrawn; version 2.0.0 used the modulus `q = 3329` for all ranks. See `ERRATA.md`.
