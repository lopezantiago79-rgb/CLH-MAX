# CLH-MAX: a lattice-based KEM proposal over the prime cyclotomic ring Z_q[X]/Φ_257(X)

> **Status: unrefereed technical note.** CLH-MAX has not been peer-reviewed or analysed by the community. The reference implementation is **not constant-time** and must **not** be used to protect real data. Use standardised schemes such as ML-KEM instead.

CLH-MAX is a Module-LWE key encapsulation mechanism in the style of Kyber/ML-KEM in which the ring Z_q[X]/(X^256+1) is replaced by R_q = Z_q[X]/Φ_257(X). For primes q that are primitive roots modulo 257, R_q is a field (F_q^256). This repository contains the paper, its machine-checked game-hopping inequality in Lean 4, and the scripts behind every number in the paper.

The paper makes **no claim** of higher concrete security than ML-KEM. Its contribution is a fully specified alternative ring instantiation with its correctness and reduction analysis, reproducible scripts, and a list of open problems.

## Current version

**2.1.1** (November 2026) — DOI: [10.5281/zenodo.24545562](https://doi.org/10.5281/zenodo.24545562)

All versions (always resolves to the latest): [10.5281/zenodo.22883946](https://doi.org/10.5281/zenodo.22883946)

| Version | Notes |
|---|---|
| 2.1.1 | Corrects two stale numerical values in Section 9 and a typo in Section 12. No result changes. |
| 2.1.0 | Final parameter family q = 2663 / 3329 / 3643 (η = 2), certified failure bounds. DOI [10.5281/zenodo.24167384](https://doi.org/10.5281/zenodo.24167384) |
| 2.0.0 – 2.0.2 | **Use moduli that do not satisfy the rigorous failure bound** of Theorem 3. Superseded. |
| ≤ 1.6 | Contain claims that are **withdrawn**. |

See [`ERRATA.md`](ERRATA.md) for details of every correction.

## Parameter sets (η = 2, no ciphertext compression)

| Set | k | q | pk (B) | ciphertext (B) | sk (B) | certified log2 δ ≤ |
|---|---|---|---|---|---|---|
| CLH-MAX-512 | 2 | 2663 | 800 | 1152 | 1600 | −134.57 |
| CLH-MAX-768 | 3 | 3329 | 1184 | 1536 | 2368 | −143.95 |
| CLH-MAX-1024 | 4 | 3643 | 1568 | 1920 | 3136 | −131.17 |

## Repository contents

- `main.tex`, `CLH_MAX.pdf`: the paper (compile with pdfLaTeX).
- `ClhMaxSecurity.lean` (one ring component, k = 1) and `ClhMaxModule.lean` (arbitrary module rank k): formalise the IND-CPA game-hopping inequality. They compile against Mathlib v4.35.0 (see `lakefile.lean` and `lean-toolchain`), use no hardness axiom and no `sorry`; `#print axioms` reports only `propext`, `Classical.choice`, `Quot.sound`. They do **not** formalise the hardness of (M)LWE, running times, or the Fujisaki–Okamoto transform.
- `scripts/`: Python scripts (see below).
- `results/`: raw outputs, including the unmodified lattice-estimator output (`estimator_batch_2026-11.txt`).
- `ERRATA.md`, `LICENSE-paper.md`.

(If your local layout differs, adjust the paths above.)

## Scripts

| Script | Purpose |
|---|---|
| `dfp.py` | heuristic decryption failure probability (exact convolution, independence assumption) |
| `validate_dfp.py` | Monte Carlo validation of the failure model |
| `rigorous_dfp.py` | Chernoff bound of Theorem 3 in float64 |
| `certified_dfp.py` | the same bound with interval arithmetic (`mpmath.iv`) |
| `exact_dfp_check.py` | independent check with exact rational arithmetic |
| `compression_dfp.py` | ciphertext compression and native-NTT-modulus computations |
| `asym_search.py`, `estimate_batch.py` | scan and lattice-estimator runs for asymmetric noise |
| `clh_max_ref.py` | reference implementation (PKE, FO-based KEM, ring multiplication by folding and by an NTT over the auxiliary prime P = 469762049, self-test). Not constant-time. |

Requirements: Python 3 with `numpy` and `mpmath`; the [lattice-estimator](https://github.com/malb/lattice-estimator) for the estimator runs.

## Building the Lean files

```
lake build
```

with the Mathlib version pinned in `lakefile.lean`.

## How to cite

```bibtex
@misc{lopezheinzen2026clhmax,
  author    = {L{\'o}pez Heinzen, Santiago},
  title     = {{CLH-MAX}: A Lattice-Based {KEM} Proposal over the Prime Cyclotomic Ring $\mathbb{Z}_q[X]/\Phi_{257}(X)$},
  year      = {2026},
  note      = {Version 2.1.1, unrefereed technical note},
  doi       = {10.5281/zenodo.24545562}
}
```

## Contact

Santiago López Heinzen, independent researcher — lopezantiago79@gmail.com. Critiques, attack ideas and reviews are welcome.
