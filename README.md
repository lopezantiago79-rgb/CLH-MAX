# Machine-Checked IND-CPA Security Reduction for CLH MAX KEM in Lean 4

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1098765.svg)](https://doi.org/10.5281/zenodo.1098765)
[![Lean 4](https://img.shields.io/badge/Lean_4-v4.x.x-blue.svg)](https://leanprover.github.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains the machine-checked formalization of the **IND-CPA security reduction** for the **CLH MAX Key Encapsulation Mechanism (KEM)**, implemented in [Lean 4](https://leanprover.github.io/) using `Mathlib`.

The security proof is structured as a monadic three-game-hopping sequence ($\text{Game}_0$, $\text{Game}_1$, $\text{Game}_2$) using the Probability Mass Function (`PMF`) monad. The reduction bounds the adversary's advantage against the decision Ring Learning With Errors (DRLWE) problem through the triangle inequality on real numbers ($\mathbb{R}$). 

**Verification Status:** The main reduction theorem (`clh_max_security_reduction`) compiles with **zero `sorry` placeholders** and **0 compilation warnings/errors**.

---

## 📐 Geometric & Algebraic Rationale

The **CLH MAX** scheme bridges abstract cyclotomic quotient rings $R_q = \mathbb{Z}_q[X]/(X^n + 1)$ with discrete geometry on $n$-dimensional lattice structures $\mathbb{Z}^n$:

1. **Isomorphic Vector Embedding:** Polynomial coefficient vectors are canonically mapped to lattice grid coordinates.
2. **Negacyclic Shifts:** Multiplication by $X \pmod{X^n + 1}$ acts as an antisymmetric rotation, preventing degree expansion.
3. **Bounded Metric Perturbations:** Noise elements $e \leftarrow \chi$ shift exact lattice points within a bounded Euclidean sphere, aligning security directly with the Bounded Distance Decoding (BDD) / DRLWE hardness assumptions.

---

## 📁 Repository Structure

```text
.
├── ClhMaxSecurity.lean   # Core Lean 4 formalization file
├── lakefile.lean         # Lake package configuration
├── lean-toolchain        # Specified Lean 4 version toolchain
├── paper/
│   ├── main.tex          # LaTeX manuscript source (arXiv format)
│   └── main.pdf          # Compiled PDF manuscript
├── LICENSE               # Open-source license (MIT)
└── README.md             # Project documentation
