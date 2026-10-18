# Exact decryption-failure estimate for CLH-MAX (independence heuristic, no compression).
# Usage: python3 dfp.py   (needs numpy)
import numpy as np
from math import log2, comb
def cbd(eta):
    return np.array([comb(2*eta, i) for i in range(2*eta+1)], float)/4**eta, eta
def prod_pmf(x, y):
    p1, o1 = cbd(x); p2, o2 = cbd(y); d = {}
    for i, a in enumerate(range(-o1, o1+1)):
        for j, b in enumerate(range(-o2, o2+1)):
            d[a*b] = d.get(a*b, 0) + p1[i]*p2[j]
    off = max(abs(v) for v in d); arr = np.zeros(2*off+1)
    for v, p in d.items(): arr[v+off] += p
    return arr, off
def conv_pow(p, off, m):
    res, roff, base, boff = np.array([1.0]), 0, p.copy(), off
    while m:
        if m & 1: res = np.convolve(res, base); roff += boff
        m >>= 1
        if m: base = np.convolve(base, base); boff *= 2
    return res, roff
def delta(k, eta1, eta2, q):
    thr = q // 4
    pa, oa = prod_pmf(eta1, eta1); pb, ob = prod_pmf(eta1, eta2)
    d1, o1 = conv_pow(pa, oa, k*511); d2, o2 = conv_pow(pb, ob, k*511)
    d, o = np.convolve(d1, d2), o1 + o2
    p2, oo = cbd(eta2); d, o = np.convolve(d, p2), o + oo
    idx = np.arange(len(d)) - o
    t = d[np.abs(idx) >= thr].sum()
    return log2(t), log2(t) + 8           # per coefficient, union over 256
if __name__ == "__main__":
    for k, e1, e2, q in [(2,2,2,2531), (3,2,2,3329), (4,2,2,3557), (4,2,2,3329)]:
        print(k, e1, e2, q, delta(k, e1, e2, q))
