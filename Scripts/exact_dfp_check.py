"""Independent verification of the certified Chernoff bound with EXACT rational arithmetic (no floating point,
no interval library).  All quantities are positive and every operation is monotone, so replacing each value by a
rational UPPER bound (rounded up at every step) yields a valid upper bound of delta.
  * cosh(x) <= truncated Taylor sum + 2 x^(2N+2)/(2N+2)!  (x <= 1)
  * exp(-y) <= 1/L with L a truncated Taylor sum of exp(y/2^8), squared 8 times, rounded DOWN
  * transfer-matrix vectors are rounded UP to multiples of 2^-1024
The result is a rational number T with  delta <= T;  we print the largest integer X with T <= 2^-X.
Same lambdas as certified_dfp.py.   Usage: python3 exact_dfp_check.py"""
from fractions import Fraction as F
from math import comb, factorial
import dfp, rigorous_dfp
PREC = 2**1024
def up(x):
    return F(-((-x.numerator * PREC) // x.denominator), PREC)
def dn(x):
    return F((x.numerator * PREC) // x.denominator, PREC)
def cosh_up(x):                                   # upper bound of cosh(x), 0 <= x <= 1, x rational
    N = 14
    s = sum(x**(2 * n) / factorial(2 * n) for n in range(N + 1))
    return up(s + 2 * x**(2 * N + 2) / factorial(2 * N + 2))
def powup(a, e):
    r = F(1)
    for _ in range(e): r = up(r * a)
    return r
def exp_lower(y):                                 # lower bound of exp(y), y >= 0 rational
    z = y / 2**8
    S = dn(sum(z**n / factorial(n) for n in range(31)))
    for _ in range(8): S = dn(S * S)
    return S
def M1_upper(lam, eta=2):
    n = 2 * eta + 1; z = eta
    p = [F(comb(2 * eta, v), 4**eta) for v in range(n)]
    W = [[powup(cosh_up(lam * abs(v - u) / 2), 2 * eta) for v in range(n)] for u in range(n)]
    f = {1: p[:]}
    for t in range(2, 257):
        f[t] = [up(p[v] * sum(f[t - 1][u] * W[u][v] for u in range(n))) for v in range(n)]
    s = {257: [F(1)] * n}
    for t in range(256, 0, -1):
        s[t] = [up(sum(W[u][v] * p[v] * s[t + 1][v] for v in range(n))) for u in range(n)]
    out = []
    for i in range(256):
        ts = (256 * pow(i + 1, -1, 257)) % 257
        out.append(s[1][z] if ts == 1 else up(sum(f[ts - 1][u] * W[u][z] for u in range(n)) * s[ts][z]))
    return out
def certified_exponent(k, q, lam, eta=2):
    lam = F(lam); t = dfp.threshold(q)
    M1 = M1_upper(lam, eta); C = powup(cosh_up(lam / 2), 2 * eta); L = exp_lower(lam * t)
    total = F(0)
    for m in M1: total += up(powup(m, 2 * k) * C / L)
    total = up(2 * total)
    n = total.numerator * (PREC // total.denominator) if PREC % total.denominator == 0 else None
    e = (n - 1).bit_length()                      # total <= 2^(e - 1024)
    return 1024 - e, total
if __name__ == "__main__":
    print("k  q     t_q   lambda     exact-rational check: delta <= 2^-X  with X =   (interval-arithmetic value)")
    ref = {(2, 2663): -134.57, (3, 3329): -143.95, (4, 3617): -129.12, (4, 3643): -131.17, (2, 2531): -121.65, (4, 3557): -124.75}
    for (k, q), r in ref.items():
        lam_star, _ = rigorous_dfp.best_lambda_and_bound(k, 2, q)
        lam = F(round(float(lam_star) * 256), 256)
        X, _ = certified_exponent(k, q, lam)
        print(f"{k}  {q}  {dfp.threshold(q):4d}  {float(lam):.5f}    X = {X}                    ({r})")
