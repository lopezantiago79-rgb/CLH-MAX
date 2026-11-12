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

- `main.tex`, `paper/CLH_MAX.pdf` — the paper (version 2.1.0).
- `ClhMaxSecurity.lean` — Lean 4 / Mathlib proof of the game-hopping inequality, one ring component (`k = 1`).
- `ClhMaxModule.lean` — the same inequality for arbitrary module rank `k`.
- `lakefile.lean`, `lean-toolchain` — Lean project files (Lean and Mathlib `v4.35.0`).
- `scripts/dfp.py` — heuristic decryption-failure estimate (exact convolution, independence assumption).
- `scripts/rigorous_dfp.py`, `scripts/certified_dfp.py`, `scripts/exact_dfp_check.py` — rigorous Chernoff bound on the failure probability (float64, interval arithmetic, exact rational arithmetic).
- `scripts/validate_dfp.py` — Monte Carlo validation of the heuristic.
- `scripts/compression_dfp.py` — effect of ciphertext compression, and the native-NTT-modulus check (`q = 12289`).
- `scripts/clh_max_ref.py` — reference implementation (PKE and `FO^⊥̸` KEM, self-test). Not constant-time.
- `scripts/asym_search.py`, `scripts/estimate_batch.py` — asymmetric-noise scan and its lattice-estimator batch.
- `scripts/estimate_clh_max.py`, `scripts/estimate_candidates.py`, `scripts/estimate_message_recovery.py` — earlier lattice-estimator runs.
- `results/` — raw outputs of the scripts and of the lattice-estimator.
- `ERRATA.md` — corrections relative to earlier versions. **Later versions supersede earlier ones.**

## Parameter sets

All sets use centered binomial noise `η = 2`, no ciphertext compression, odd modulus `q` chosen per rank.

| Set | k | n = 256k | q | pk (B) | ct (B) | ML-KEM ct (B) | sk (B) | certified log2 δ ≤ |
|---|---|---|---|---|---|---|---|---|
| CLH-MAX-512 | 2 | 512 | 2663 | 800 | 1152 | 768 | 1600 | -134.57 |
| CLH-MAX-768 | 3 | 768 | 3329 | 1184 | 1536 | 1088 | 2368 | -143.95 |
| CLH-MAX-1024 | 4 | 1024 | 3643 | 1568 | 1920 | 1568 | 3136 | -131.17 |

`δ` is bounded rigorously by a Chernoff bound with an exact moment generating function (no independence
assumption), evaluated with interval arithmetic and re-checked with exact rational arithmetic.
Earlier versions used `q = 2531` (`k = 2`) and `q = 3557` (`k = 4`); under the rigorous bound they give
`2^-121.65` and `2^-124.75`, so they do **not** reach `2^-128` and were replaced.

## KEM

`FO^⊥̸` of Hofheinz–Hövelmanns–Kiltz (K = H(m‖c), implicit rejection with a secret seed). In the random-oracle model

`Adv^IND-CCA ≤ q_RO·δ + 3·q_RO/2^256 + 3·(Adv^MLWE_{k,k} + Adv^MLWE_{k+1,k})`

(Theorem 2 of the paper, with its hypotheses checked). Because of the `q_RO·δ` term the certified `δ` supports about
134, 143 and 131 bits for `k = 2, 3, 4`; no security levels are assigned. No claim is made in the quantum random-oracle model.

## What the Lean files prove (and what they do not)

Both files prove, for any commutative ring `R`, any distributions (with the distribution of the ring element
added to the message translation-invariant, e.g. uniform) and any adversary `A`:

`advIND ≤ (eps1 true + eps2 true) + (eps1 false + eps2 false)`

where `eps1`, `eps2` are the advantages of explicit distinguishers against (Module-)LWE with `k` and `k+1`
samples. They use no hardness axiom and no `sorry`; `#print axioms` reports only `propext`,
`Classical.choice`, `Quot.sound`. They do **not** formalise hardness of (M)LWE, running times, or the
Fujisaki–Okamoto transform.

Build:

```
lake exe cache get
lake build
```

## Main results (see the paper for details)

- IND-CPA security reduces to two decision-MLWE instances (paper proof; machine-checked game-hopping inequality in Lean for arbitrary `k`).
- Exact decoding thresholds: a decoding error forces `|E_i| ≥ t_q` (`⌊q/4⌋` if `q ≡ 1 mod 4`, `⌈q/4⌉` if `q ≡ 3 mod 4`).
- With the ML-KEM modulus `q = 3329` the rank-4 set has a rigorous `δ` bound of only `2^-108.7`; the modulus is therefore chosen per rank.
- Generic MLWE estimates (lattice-estimator, key and message recovery, same call for CLH-MAX and ML-KEM), weakest instance, dual hybrid:
  `k = 2`: `2^136.2` vs `2^136.6` (−0.4 bit); `k = 3`: identical (`2^196.4`); `k = 4`: `2^259.2` vs `2^262.3` (−3.1 bits).
  The ring itself plays no role in these estimates.
- Asymmetric noise (`η₁ ≠ η₂`) does not help: lowering `η₂` weakens the message-recovery instance by more than it strengthens key recovery (3.5 to 8.9 bits below ML-KEM).
- Ciphertext compression with ML-KEM's parameters breaks `δ` (heuristic about `2^-92`, `2^-86`, `2^-105`), so ciphertexts are 50 %, 41 % and 22 % larger than ML-KEM's.
- No NTT modulo `q`; an exact NTT over an auxiliary prime works because one operand is always small (not benchmarked). A modulus with a native NTT (`q = 12289`) would need `η = 11` for the same security and gives `δ ≈ 2^-98`.
- Ring-specific attacks from the literature (Eisenträger–Hallgren–Lauter, Elias–Lauter–Ozman–Stange, Chen–Lauter–Stange) require a small finite-field image of the ring; since `q` is inert the only image is the ring itself (`q^256` elements). This is a check of known attacks, not a proof of security.

## Reproducing the numbers

```
python3 scripts/dfp.py
python3 scripts/rigorous_dfp.py
python3 scripts/certified_dfp.py
python3 scripts/exact_dfp_check.py
python3 scripts/validate_dfp.py
python3 scripts/compression_dfp.py
python3 scripts/clh_max_ref.py
```

The estimator scripts must be run inside a checkout of the
[lattice-estimator](https://github.com/malb/lattice-estimator); raw outputs are in `results/`.

## Open problems

Tighter rigorous bounds on `δ` and finer compression settings; narrowing the residual gap of about three bits
at `k = 4`; an optimised, constant-time implementation and benchmarks; a complete ring-specific cryptanalysis
(including whether the dual-RLWE narrow-error attack of Chen–Lauter–Stange has an adaptation to this setting);
a machine-checked proof of the Fujisaki–Okamoto transform.

## License

This repository is dual-licensed:

- **Code** (Lean files, scripts): GNU Affero General Public License v3.0 (AGPL-3.0).
  See [`LICENSE`](LICENSE).
- **Paper** (`main.tex` and the PDF): Creative Commons Attribution 4.0 International
  (CC BY 4.0). See [`LICENSE-paper.md`](LICENSE-paper.md).

## How to cite

Santiago López Heinzen, *CLH-MAX: A Lattice-Based KEM Proposal over the Prime Cyclotomic
Ring Z_q[X]/Φ_257(X)*, version 2.1.0, 2026.
Zenodo: https://doi.org/10.5281/zenodo.24167384

All versions (always resolves to the latest): https://doi.org/10.5281/zenodo.22883946

Earlier Zenodo versions (v1 to 2.0.2) contain earlier versions of this work. Versions up to 1.6 contain claims
that are withdrawn; versions 2.0.0 to 2.0.2 use moduli that do not satisfy the rigorous failure bound. See `ERRATA.md`.
