# CLH-MAX — Errata and changelog

## v1 → v2.0.0

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

## v2.0.0 → v2.0.1

1. **Modulus per module rank.** Version 2.0.0 used `q = 3329` for all ranks. With the exact
   decryption-failure computation, the rank-4 set at `q = 3329` has δ ≈ 2^-117 (does not reach
   2^-128). Version 2.0.1 uses `q = 2531` (k = 2), `q = 3329` (k = 3), `q = 3557` (k = 4), all
   with δ ≤ 2^-133 (independence heuristic).
2. **Message-recovery instance.** Version 2.0.0 estimated only key recovery. For ML-KEM-512 the
   message-recovery instance is the weakest (dual hybrid 2^136.6 vs 2^139.7), so the earlier
   statement that CLH-MAX-512 (η = 2, q = 3329) was ~7 bits weaker than ML-KEM-512 is replaced:
   CLH-MAX-512 (q = 2531) is within 0.2 bits of the weakest ML-KEM-512 instance; CLH-MAX-1024
   (q = 3557) is about 1.9 bits below ML-KEM-1024.
3. **Introduction.** Removed the incorrect statement that NTRU Prime uses prime-conductor
   cyclotomic rings (its ring is `Z[x]/(x^p - x - 1)`). Added Round5 as prior use of prime-conductor
   cyclotomic rings; no novelty is claimed for the ring.
4. **Scripts.** `scripts/dfp.py` now takes `q` as a parameter; added
   `scripts/estimate_candidates.py` and `scripts/estimate_message_recovery.py`.

## v2.0.1 → v2.0.2

1. **Arithmetic.** Version 2.0.1 said that none of the moduli admits an NTT. This is true modulo
   `q`, but exact products can be computed with an NTT over an auxiliary prime (e.g.
   `469762049 = 7*2^26+1`) because every product in the scheme has one small operand. Verified
   against the explicit reduction modulo `Φ_257` (`scripts/clh_max_ref.py`). Not benchmarked.
2. **Ciphertext size.** New computation (`scripts/compression_dfp.py`): with ML-KEM's compression
   parameters the decryption failure probability is about `2^-83`, `2^-86`, `2^-100` for `k = 2, 3, 4`
   (it does not reach `2^-128`), so uncompressed ciphertexts are 50 %, 41 % and 22 % larger than
   ML-KEM's. A modulus with a native NTT (`q = 12289`) would need `η = 11` for the same security and
   gives `δ ≈ 2^-98`.
3. **Failure model.** Added a Monte Carlo validation (`scripts/validate_dfp.py`): agreement within 1 %
   up to about `3.5σ`; a possible small excess in the far tail for `k = 2` cannot be excluded.
4. **Ring-specific considerations.** New section: hypotheses of the homomorphism-based attacks
   (Eisenträger-Hallgren-Lauter, Elias-Lauter-Ozman-Stange, Chen-Lauter-Stange) checked against the
   field ring. This is not a proof of security.
5. **Lean.** Added `ClhMaxModule.lean`: the game-hopping inequality for arbitrary module rank `k`.
6. **Presentation.** Keywords added; theorem, lemma, proposition numbering is now per environment
   (the first theorem was previously numbered 7); open problems updated; a "Status" paragraph states
   that the note is unrefereed and that CLH-MAX must not be used to protect real data.
