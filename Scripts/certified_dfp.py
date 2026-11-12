"""Certified (interval-arithmetic) evaluation of the rigorous Chernoff bound on the decryption failure
probability of CLH-MAX.  Same mathematics as rigorous_dfp.py; every number is an interval computed with
mpmath.iv (outward rounding), lambda is a dyadic rational (exactly representable), the transfer-matrix vectors are
computed once per lambda (prefix/suffix products) and the 256 coefficients are obtained from them.
The printed value is the UPPER end of the interval for log2(delta).
Caveat: this relies on mpmath's interval implementation; an independent check with another tool (e.g. Arb)
would strengthen the certification.   Usage: python3 certified_dfp.py"""
from math import comb
from mpmath import iv
import dfp, rigorous_dfp
iv.dps = 50
def ivcosh(x): return (iv.exp(x) + iv.exp(-x)) / 2

def certified_M1(lam, eta=2):
    """Intervals enclosing M1_i(lam) for i = 0..255 (lam must be exactly representable)."""
    n = 2 * eta + 1; z = eta
    p = [iv.mpf(comb(2 * eta, v)) / iv.mpf(4) ** eta for v in range(n)]          # CBD probabilities (dyadic, exact)
    lam = iv.mpf(lam)
    W = [[ivcosh(lam * (v - u) / 2) ** (2 * eta) for v in range(n)] for u in range(n)]
    f = {1: p[:]}                                                                 # prefix vectors, normal nodes 1..t
    for t in range(2, 257):
        f[t] = [p[v] * sum(f[t - 1][u] * W[u][v] for u in range(n)) for v in range(n)]
    s = {257: [iv.mpf(1)] * n}                                                    # suffix vectors, nodes t+1..257 normal
    for t in range(256, 0, -1):
        s[t] = [sum(W[u][v] * p[v] * s[t + 1][v] for v in range(n)) for u in range(n)]
    out = []
    for i in range(256):
        tstar = (256 * pow(i + 1, -1, 257)) % 257
        if tstar == 1: out.append(s[1][z])
        else: out.append(sum(f[tstar - 1][u] * W[u][z] for u in range(n)) * s[tstar][z])
    return out

def certified_log2delta(k, q, lam, eta=2):
    t = dfp.threshold(q); M1 = certified_M1(lam, eta); lam_iv = iv.mpf(lam)
    base = -lam_iv * t + 2 * eta * iv.log(ivcosh(lam_iv / 2))
    total = sum(iv.exp(base + 2 * k * iv.log(m)) for m in M1)
    return (iv.log(2 * total) / iv.log(2)).b          # upper end of the interval

if __name__ == "__main__":
    # cross-check one coefficient against the float64 implementation
    lam = 0.25; l1 = rigorous_dfp.lnM1_all(lam, 2); M = certified_M1(lam)
    print("cross-check ln M1 (float64 vs interval), i = 0, 100, 255:", [(round(float(l1[i]), 9), float(iv.log(M[i]).mid)) for i in (0, 100, 255)])
    print("\nk  q     t_q   lambda    float64 optimum   CERTIFIED upper bound on log2 delta")
    for k, q in ((2, 2663), (3, 3329), (4, 3617), (4, 3643), (2, 2531), (4, 3557)):
        lam_star, f64 = rigorous_dfp.best_lambda_and_bound(k, 2, q)
        lam_d = round(float(lam_star) * 256) / 256                                # dyadic rational
        print(f"{k}  {q}  {dfp.threshold(q):4d}  {lam_d:.5f}   {f64:8.2f}          {float(certified_log2delta(k, q, lam_d)):8.2f}")
