# CLH-MAX

A research proposal for a lattice-based key encapsulation mechanism (KEM) in the style of
Kyber/ML-KEM, using the prime cyclotomic ring `Z_q[X]/Φ_257(X)` instead of `Z_q[X]/(X^256+1)`.
For primes `q` that are primitive roots modulo 257 the polynomial `Φ_257` is irreducible, so the
ring is the field `F_{q^256}`.

**Status:** unrefereed technical note. CLH-MAX has not been analysed by the community, the reference
implementation is not constant-time, and it **must not be used to protect real data**. Use standardised
schemes such as ML-KEM instead. No claim is made that CLH-MAX is more secure than ML-KEM.

Author: Santiago López Heinzen — lopezantiago79@gmail.com

## Repository contents

- `main.tex`, `paper/CLH_MAX.pdf` — the paper (version 2.0.2).
- `ClhMaxSecurity.lean` — Lean 4 / Mathlib proof of the game-hopping inequality, one ring component (`k = 1`).
- `ClhMaxModule.lean` — the same inequality for arbitrary module rank `k`.
- `lakefile.lean`, `lean-toolchain` — Lean project files (Lean and Mathlib `v4.35.0`).
- `scripts/dfp.py` — exact decryption-failure probability computation.
- `scripts/validate_dfp.py` — Monte Carlo validation of the failure model.
- `scripts/compression_dfp.py` — effect of ciphertext compression, and the native-NTT-modulus check (`q = 12289`).
- `scripts/clh_max_ref.py` — reference implementation (PKE and FO-based KEM, self-test). Not constant-time.
- `scripts/estimate_clh_max.py`, `scripts/estimate_candidates.py`, `scripts/estimate_message_recovery.py` — lattice-estimator runs.
- `results/` — raw, unmodified lattice-estimator output.
- `ERRATA.md` — corrections relative to earlier versions. **Later versions supersede earlier ones.**

## Parameter sets

All sets use centered binomial noise `η = 2`, no ciphertext compression.

| Set | k | n = 256k | q | pk (B) | ct (B) | ML-KEM ct (B) | sk (B) | log2 δ |
|---|---|---|---|---|---|---|---|---|
| CLH-MAX-512 | 2 | 512 | 2531 | 800 | 1152 | 768 | 1632 | -133.5 |
| CLH-MAX-768 | 3 | 768 | 3329 | 1184 | 1536 | 1088 | 2400 | -155.9 |
| CLH-MAX-1024 | 4 | 1024 | 3557 | 1568 | 1920 | 1568 | 3168 | -133.7 |

`δ` is computed exactly under the usual independence heuristic and validated by simulation down to
probabilities of about `10^-5` (see the paper).

## What the Lean files prove (and what they do not)

Both files prove, for any commutative ring `R`, any distributions (with the distribution of the
ring element added to the message translation-invariant, e.g. uniform) and any adversary `A`:

`advIND ≤ (eps1 true + eps2 true) + (eps1 false + eps2 false)`

where `eps1`, `eps2` are the advantages of explicit distinguishers against (Module-)LWE with `k`
and `k+1` samples. They use no hardness axiom and no `sorry`; `#print axioms` reports only
`propext`, `Classical.choice`, `Quot.sound`.

They do **not** formalise hardness of (M)LWE, running times, or the Fujisaki-Okamoto transform.

Build:

```
lake exe cache get
lake build
```

## Main results (see the paper for details)

- IND-CPA security reduces to two decision-MLWE instances (paper proof; machine-checked game-hopping inequality in Lean for arbitrary `k`).
- With the ML-KEM modulus `q = 3329` the rank-4 set has `δ ≈ 2^-117`; choosing the modulus per rank (`q = 2531, 3329, 3557`) gives `δ ≤ 2^-133` for all three sets.
- Generic MLWE estimates (lattice-estimator, key and message recovery, same call for CLH-MAX and ML-KEM): identical to ML-KEM-768 for `k = 3`; `+0.2` bits vs. the weakest ML-KEM-512 instance for `k = 2`; `-1.9` bits vs. ML-KEM-1024 for `k = 4`. The ring itself plays no role in these estimates.
- Ciphertext compression with ML-KEM's parameters breaks `δ` (about `2^-83`, `2^-86`, `2^-100`), so ciphertexts are 50 %, 41 % and 22 % larger than ML-KEM's.
- No NTT modulo `q`; an exact NTT over an auxiliary prime works because one operand is always small (not benchmarked). A modulus with a native NTT (`q = 12289`) would need `η = 11` for the same security and gives `δ ≈ 2^-98`.
- Ring-specific attacks from the literature (Eisenträger-Hallgren-Lauter, Elias-Lauter-Ozman-Stange, Chen-Lauter-Stange) require a small finite-field image of the ring; since `q` is inert the only image is the ring itself (`q^256` elements). This is a check of known attacks, not a proof of security.

## Reproducing the numbers

```
python3 scripts/dfp.py
python3 scripts/validate_dfp.py
python3 scripts/compression_dfp.py
python3 scripts/clh_max_ref.py
```

The estimator scripts must be run inside a checkout of the
[lattice-estimator](https://github.com/malb/lattice-estimator); raw outputs are in `results/`.

## Open problems

A rigorous bound on `δ` and finer compression settings; narrowing the residual gap of about two bits
at `k = 4`; an optimised, constant-time implementation and benchmarks; a complete ring-specific
cryptanalysis (including whether the dual-RLWE narrow-error attack of Chen-Lauter-Stange has an
adaptation to this setting); a machine-checked proof of the Fujisaki-Okamoto transform.

## License

This repository is dual-licensed:

- **Code** (Lean files, scripts): GNU Affero General Public License v3.0 (AGPL-3.0).
  See [`LICENSE`](LICENSE).
- **Paper** (`main.tex` and the PDF): Creative Commons Attribution 4.0 International
  (CC BY 4.0). See [`LICENSE-paper.md`](LICENSE-paper.md).

## How to cite

Santiago López Heinzen, *CLH-MAX: A Lattice-Based KEM Proposal over the Prime Cyclotomic
Ring Z_q[X]/Φ_257(X)*, version 2.0.2, 2026.
Zenodo: https://doi.org/10.5281/zenodo.23705527

All versions (always resolves to the latest): https://doi.org/10.5281/zenodo.22883946

Earlier Zenodo versions (v1 to 1.6) contain the previous version of this work, whose claims
are withdrawn; version 2.0.0 used the modulus `q = 3329` for all ranks. See `ERRATA.md`.
