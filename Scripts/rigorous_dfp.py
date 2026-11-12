"""Rigorous (heuristic-free) Chernoff bound on the CLH-MAX decryption failure probability (uncompressed).

Coefficient i of e*r in Z[X]/Phi_257 equals sum_l c_l r_l with c_l = e'_{b+s} - e'_b (b = 256-l, s = i+1 mod 257,
e'_256 := 0).  Given e, the r_l are independent, so  E[exp(lam*T)] = E_e[ prod_l cosh(lam*c_l/2)^(2*eta) ]
exactly.  The c_l are differences along a single path of 257 nodes (nodes x_t = t*s mod 257), hence the
expectation over e is computed exactly with a 5x5 transfer matrix.  T = e*r - s*e1 + e2 has independent parts, so
ln M(lam) = 2k ln M1(lam) + ln M_e2(lam).  A decoding error in coefficient i forces |E_i| >= threshold(q)
(Lemma "Decoding" of the paper), so  delta <= 2 * sum_i exp(-lam*t + ln M(lam))  for any lam > 0.
NOTE: this script uses float64; scripts/certified_dfp.py re-evaluates the bound with interval arithmetic.
Usage: python3 rigorous_dfp.py"""
import numpy as np
from math import comb, log
import dfp
from compression_dfp import usvp_beta

LAMS = np.linspace(0.02, 0.8, 157)
_cache = {}
def lnM1_all(lam, eta=2, eta_w=None):
    eta_w = eta if eta_w is None else eta_w
    key = (round(float(lam), 6), eta, eta_w)
    if key in _cache: return _cache[key]
    vals = np.arange(-eta, eta + 1); p = np.array([comb(2 * eta, int(v) + eta) for v in vals]) / 4.0**eta; n = len(vals)
    W = np.cosh(lam * (vals[None, :] - vals[:, None]) / 2.0) ** (2 * eta_w)
    sv = np.arange(1, 257)
    tstar = np.array([(256 * pow(int(s), -1, 257)) % 257 for s in sv])
    delta0 = np.zeros(n); delta0[eta] = 1.0
    f = None; logscale = np.zeros(256)
    for t in range(1, 258):
        P = np.tile(p, (256, 1)); P[tstar == t] = delta0
        f = P if t == 1 else (f @ W) * P
        sc = f.sum(axis=1); f = f / sc[:, None]; logscale += np.log(sc)
    _cache[key] = logscale
    return logscale
def best_lambda_and_bound(k, eta, q):
    t = dfp.threshold(q); best = np.full(256, np.inf); tot = []
    for lam in LAMS:
        val = -lam * t + 2 * k * lnM1_all(lam, eta) + 2 * eta * np.log(np.cosh(lam / 2))
        tot.append((log(2.0) + np.logaddexp.reduce(val), lam)); best = np.minimum(best, val)
    lam_star = min(tot)[1]                                       # lam minimising the summed bound
    per_coeff_opt = (log(2.0) + np.logaddexp.reduce(best)) / log(2.0)
    return lam_star, per_coeff_opt
def rigorous_log2delta(k, eta, q): return best_lambda_and_bound(k, eta, q)[1]
def rigorous_log2delta_asym(k, eta1, eta2, q):
    """Key/secret/r noise psi_eta1, e1/e2 noise psi_eta2.  E = e^T r - s^T e1 + e2:
    k terms with nodes psi_eta1 and weights psi_eta1 (e*r), k terms with nodes psi_eta1 and weights psi_eta2 (s*e1),
    and one psi_eta2 term (e2)."""
    t = dfp.threshold(q); best = np.full(256, np.inf)
    for lam in LAMS:
        val = -lam * t + k * lnM1_all(lam, eta1, eta1) + k * lnM1_all(lam, eta1, eta2) + 2 * eta2 * np.log(np.cosh(lam / 2))
        best = np.minimum(best, val)
    return (log(2.0) + np.logaddexp.reduce(best)) / log(2.0)

def order257(q):
    x, y, o = q % 257, q % 257, 1
    while y != 1: y = y * x % 257; o += 1
    return o
def isprime(n): return n > 1 and all(n % d for d in range(2, int(n**.5) + 1))
if __name__ == "__main__":
    lam = 0.01; l1 = lnM1_all(lam, 2); print("small-lambda check: 2*lnM1/lam^2 =", round(2 * l1[0] / lam**2, 1), "(expected ~510)")
    print("\nk  q     t_q   rigorous log2 delta (float64)")
    for k, q in ((2, 2663), (3, 3329), (4, 3643), (4, 3617), (2, 2531), (4, 3557), (4, 3329)):
        print(f"{k}  {q}  {dfp.threshold(q):4d}   {rigorous_log2delta(k, 2, q):8.1f}")
    print("\nScan: valid moduli (ord_257(q) = 256) with rigorous delta < 2^-128, and the calibrated uSVP beta (eta = 2)")
    for k, lo, hi in ((2, 2531, 2800), (3, 3329, 3500), (4, 3557, 3800)):
        print(f"\nk = {k}   (ML-KEM reference beta_uSVP: 406 / 624 / 874)")
        print("  q     t_q   rigorous log2 delta   beta_uSVP")
        shown = 0
        for q in range(lo, hi):
            if isprime(q) and q != 257 and order257(q) == 256:
                d = rigorous_log2delta(k, 2, q)
                if d < -128 and shown < 5:
                    print(f"  {q}  {dfp.threshold(q):4d}   {d:8.1f}            {usvp_beta(256 * k, q, 1.0)}"); shown += 1
