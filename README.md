# CLH MAX: Post-Quantum Cryptosystem
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22883946.svg)](https://doi.org/10.5281/zenodo.22883946)
[![Lean 4 Verification](https://img.shields.io/badge/Lean_4-Verified-green.svg)](https://leanprover.github.io/)
[![arXiv](https://img.shields.io/badge/arXiv-PENDING-b31b1b.svg)](https://arxiv.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**CLH MAX** is a quantum-resistant Key Encapsulation Mechanism (KEM) based on the pure Ring Learning With Errors (Ring-LWE) problem. This repository contains the formal mathematical verification of the decryption correctness utilizing the Lean 4 proof assistant.

## Overview

Unlike conventional module-based approaches (such as ML-KEM/Kyber), CLH MAX optimizes algebraic operations over the quotient ring $R_q = \mathbb{Z}_q[x]/(x^n + 1)$ through direct nega-cyclic convolutions and the Number Theoretic Transform (NTT).

This repository focuses on the theoretical foundation and the computer-assisted proofs of the scheme's algebraic correctness. By isolating the operations to a pure ring structure, CLH MAX achieves strict algebraic exactness while avoiding the spatial overhead of module matrix arithmetic.

### Key Features
* **Pure Ring-LWE Architecture:** Eliminates module matrix overhead for highly optimized polynomial multiplication.
* **Formal Verification:** Complete decryption correctness formally proven in Lean 4 with zero open goals (`sorry`-free).
* **Security Bounds:** IND-CCA2 semantic security established via the Fujisaki-Okamoto (FO) transformation.
* **Failure Probability:** Strictly bounded to $< 2^{-128}$ using Centered Binomial Distributions ($\eta=2$).

## Repository Structure

```text
├── src/
│   └── ClhMax.lean       # Core Lean 4 formalization and decryption proofs
├── lakefile.lean         # Lean 4 package configuration
├── lean-toolchain        # Lean version pinning
├── LICENSE               # MIT License
└── README.md             # Repository documentation
