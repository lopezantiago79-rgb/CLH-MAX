# CLH-MAX — Errata and changelog (v1 → v2)

Version 1 of the manuscript and of `ClhMaxSecurity.lean` (Zenodo 10.5281/zenodo.22943292)
contained errors. They are listed here for transparency. **Version 2 supersedes version 1.**

## Mathematical / security claims withdrawn
1. *"Module-CLH MAX exceeds ML-KEM by 14–15 bits."* Withdrawn. With one lattice-estimator call
   and cost model for all instances, CLH-MAX-768/1024 give outputs identical to ML-KEM-768/1024
   (same `(n, q, noise)`); CLH-MAX-512 with η=2 is ~7 bits *below* ML-KEM-512 (η=3).
2. *"X^256+1 splits into 256 linear factors mod 3329."* Wrong: it splits into 128 quadratic
   factors (ord_512(3329) = 2).
3. *"No subfield structure."* Wrong: F_{q^256} has subfields F_{q^(2^j)}; only the absence of a
   ring decomposition is true. The cited attacks concern overstretched NTRU.
4. *Worst-case reduction with γ ≈ 602,613.* Withdrawn: the LPR13 reduction does not cover
   centered-binomial noise with q = 3329 at these parameters.
5. *Decryption failure probabilities (2^-2012, 2^-1340, 2^-1005).* Wrong. A product coefficient
   in Z_q[X]/Φ_257 sums 510–511 terms (not 256). Corrected values: 2^-231 / 2^-156 / 2^-117
   (η=2, no compression). The k=4 set does **not** reach 2^-128.
6. *"NTT-512 with q = 3329" and "2.25× overhead".* Withdrawn: 512 ∤ 3328.

## Lean formalisation
* Removed the axiom `drlwe_hardness` (it asserted zero advantage for *all* distinguishers, which
  is false and made `Adv_INDCPA = 0` derivable).
* Fixed simulator `B2` (it used `a*b + e2 + m` instead of a 2-sample LWE structure).
* `mul_uniform_eq` was stated for an arbitrary distribution `U`; the new development only
  assumes translation invariance of `U` and proves it for the uniform distribution.
* Several lemmas used in the main proof were missing from the listing.

## Reproducibility
* `scripts/dfp.py` — exact decryption-failure computation.
* `scripts/estimate_clh_max.py` and `results/estimator_output_<date>.txt` — estimator runs
  (record the estimator commit hash in the results file).
