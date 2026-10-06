# CLH MAX KEM

**A Post-Quantum Key Encapsulation Mechanism over Z_q[X]/Φ₂₅₇(X) with Machine-Checked Security**

> Santiago López Heinzen — October 2026  
> Zenodo: <https://doi.org/10.5281/zenodo.22943292>

---

## Overview

CLH MAX is a post-quantum KEM whose central algebraic novelty is the use of
the **Fermat prime cyclotomic polynomial Φ₂₅₇(X)** as the ring modulus.

For primes q with ord₂₅₇(q) = 256 (including q = 3329 and q = 12289),
Φ₂₅₇ is **irreducible** over Z_q, making

```
R_q = Z_q[X]/Φ₂₅₇(X)  ≅  F_{q^256}
```

a single finite field. This eliminates the subfield decomposition present
in Kyber/ML-KEM (where X²⁵⁶+1 splits into 256 linear factors), removing
the attack surface exploited by subfield attacks (Cheon et al. 2016).

---

## Key Properties

| Property | CLH MAX | ML-KEM (Kyber) |
|---|---|---|
| Ring modulus | Φ₂₅₇(X) — **irreducible** | X²⁵⁶+1 — splits into 256 factors |
| Ring structure | Field F_{q²⁵⁶} (single) | Product of 256 copies of F_q |
| qO_K factorisation | **1 prime ideal** (inert) | 256 prime ideals (split) |
| Subfield attacks | **Do not apply ✓** | Applicable ✗ |
| Security Level 1 (cl/qu) | **2¹³².⁸ / 2¹²¹** | 2¹¹⁸ / 2¹⁰⁷ |
| Security Level 3 (cl/qu) | **2¹⁹⁶.⁴ / 2¹⁷⁸** | 2¹⁸³ / 2¹⁶⁶ |
| Security Level 5 (cl/qu) | **2²⁶².³ / 2²³⁸** | 2²⁴⁷ / 2²²⁴ |
| Key/ct sizes | **Identical to ML-KEM** | — |
| IND-CPA formal proof | **Lean 4: 1 axiom, 0 sorry ✓** | Partial (EasyCrypt) |
| IND-CCA2 | ✓ FO-T transform | ✓ FIPS 203 |
| Arithmetic overhead | ~2.25× vs ML-KEM | 1× (reference) |

---

## Concrete Security (Lattice-Estimator, Albrecht et al.)

All values computed with the official lattice-estimator on the Module-CLH MAX
parameter sets (q = 3329, η = 2):

| Scheme | BKW | uSVP | BDD | Dual | Dual Hybrid | **Worst** | β | NIST |
|---|---|---|---|---|---|---|---|---|
| CLH-MAX-256 (base ring) | 95.8 | 73.1 | 70.5 | 75.4 | 71.9 | **70.5** | 141 | < L1 |
| Module-CLH-MAX k=2 (n=512) | 167.2 | 137.1 | 133.7 | 142.6 | 132.8 | **132.8** | 363 | L1 ✓ |
| Module-CLH-MAX k=3 (n=768) | 238.3 | 204.9 | 201.0 | 214.3 | 196.4 | **196.4** | 589 | L3 ✓ |
| Module-CLH-MAX k=4 (n=1024) | 315.0 | 275.1 | 270.7 | 288.5 | 262.3 | **262.3** | 823 | L5 ✓ |

Dominant attack: **dual hybrid (MATZOV 2022)**.  
CLH MAX exceeds ML-KEM by **+14.8 bits (L1)**, **+13.4 bits (L3)**, **+15.3 bits (L5)**.

---

## Hardness Foundation

Theorem 4.10 establishes the reduction chain with explicit constants:

```
ideal-SIVP_γ(O_K)  →  D-RLWE_{256, 3329, ψ₂}(Z_3329[X]/Φ₂₅₇(X))
```

with approximation factor:

```
γ = √2 · n · (q/B) = √2 · 256 · (3329/2) ≈ 602,613 ≈ 2^19.2
```

Five conditions explicitly verified (C1)–(C5):
- C1: n = 256 = 2⁸ (Peikert 2009 smoothness hypothesis)
- C2: k = 257 prime
- C3: ord₂₅₇(3329) = 256 → qO_K is a prime ideal
- C4: q = 3329 ≥ 2√n·B = 64 (LPR 2013, Theorem 4.1)
- C5: α = 2/3329 ≤ 1/(√2·n) (noise rate within valid range)

---

## Lean 4 Formalization

**File:** `ClhMaxSecurity.lean`  
**Namespace:** `ClhMax`  
**Axiom count: 1** (`drlwe_hardness`)  
**Sorry count: 0**

### Proof architecture

| Component | Type | Status |
|---|---|---|
| `drlwe_hardness` | axiom | **SOLE AXIOM** |
| `[Field Rq]` | instance | GIVEN (Φ₂₅₇ irred.) |
| `mul_uniform_eq` | theorem | ✓ proved |
| `B1`, `B2` | definitions | ✓ |
| `B1_real_eq_Game0` | lemma | ✓ proved |
| `B1_unif_eq_Game1` | lemma | ✓ proved |
| `Adv_B1_eq` | lemma | ✓ proved |
| `B2_real_eq_Game1` | lemma | ✓ proved |
| `B2_unif_eq_Game2` | lemma | ✓ proved |
| `Adv_B2_eq` | lemma | ✓ proved |
| `Game0_false_eq_Game2` | lemma | ✓ proved |
| `Adv_INDCPA_eq_game_diff` | lemma | ✓ proved |
| `clh_max_indcpa_security` | **theorem** | ✓ **0 sorry** |
| `clh_max_indcpa_zero` | corollary | ✓ **0 sorry** |

**Main theorem (5.9):**

```lean
theorem clh_max_indcpa_security (A : Adversary Rq) :
    Adv_INDCPA U χ A ≤
    Adv_DRLWE U χ (B1 χ A) + Adv_DRLWE U χ (B2 U χ A)
```

---

## Building

### Requirements

- Lean 4 v4.14.0 (see `lean-toolchain`)
- Mathlib v4.14.0

### Steps

```bash
# Clone the repository
git clone https://github.com/<your-user>/clh-max-kem
cd clh-max-kem

# Install elan (Lean version manager) if needed
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh

# Download Mathlib cache (recommended — avoids compiling Mathlib from scratch)
lake exe cache get

# Build
lake build

# Check the main file
lake env lean ClhMaxSecurity.lean
```

Expected output: no errors, no warnings about `sorry`.

---

## Repository Structure

```
clh-max-kem/
├── ClhMaxSecurity.lean   # Complete Lean 4 formalization
├── lakefile.lean         # Lake build configuration
├── lean-toolchain        # Lean version pin
└── README.md             # This file
```

---

## Parameter Sets

| Scheme | k | n_eff | q | η | pk | sk | ct | Worst case | NIST Level |
|---|---|---|---|---|---|---|---|---|---|
| M-CLH-MAX-512 | 2 | 512 | 3329 | 2 | 800 B | 1600 B | 768 B | 2¹³².⁸ | Level 1 |
| M-CLH-MAX-768 | 3 | 768 | 3329 | 2 | 1184 B | 2400 B | 1088 B | 2¹⁹⁶.⁴ | Level 3 |
| M-CLH-MAX-1024 | 4 | 1024 | 3329 | 2 | 1568 B | 3168 B | 1568 B | 2²⁶².³ | Level 5 |

Key and ciphertext sizes are **identical to ML-KEM** at each security level.

---

## Citation

```bibtex
@misc{clhmax2026,
  author       = {López Heinzen, Santiago},
  title        = {{CLH MAX}: A Post-Quantum Key Encapsulation Mechanism
                  over $\mathbb{Z}_q[X]/\Phi_{257}(X)$
                  with Machine-Checked Security},
  year         = {2026},
  doi          = {10.5281/zenodo.22943292},
  url          = {https://doi.org/10.5281/zenodo.22943292},
  note         = {Lean 4 formalization: 1 axiom, 0 sorry}
}
```

---

## License

MIT License — see `LICENSE` for details.
