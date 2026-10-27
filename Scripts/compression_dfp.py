"""Open problem (i)/(iii): effect of ML-KEM-style ciphertext compression on the decryption failure
probability of CLH-MAX, and why a modulus with 512 | q-1 (native NTT) does not work with small noise.
Model: compression error of u (du bits) and v (dv bits) is the exact error of Compress/Decompress over
uniform x in Z_q, assumed independent of the rest (the usual assumption).   Usage: python3 compression_dfp.py"""
import numpy as np
from math import log2, comb, log
import dfp

def comp_err_pmf(q, d):
    x = np.arange(q)
    y = np.floor(x * 2**d / q + 0.5).astype(np.int64) % 2**d
    xp = np.floor(y * q / 2**d + 0.5).astype(np.int64)
    err = ((xp - x + q // 2) % q) - q // 2
    lo = err.min(); cnt = np.bincount(err - lo); return cnt / q, int(-lo)      # (pmf, offset)

def conv(a, oa, b, ob): return np.convolve(a, b), oa + ob
def reflect(p, o): return p[::-1].copy(), len(p) - 1 - o

def delta_compressed(k, q, du, dv, eta=2):
    # base error E (uncompressed)
    pa, oa = dfp.prod_pmf(eta, eta)
    d1, o1 = dfp.conv_pow(pa, oa, k * 511); d2, o2 = dfp.conv_pow(pa, oa, k * 511)
    E, oE = np.convolve(d1, d2), o1 + o2
    pe, oe = dfp.cbd(eta); E, oE = conv(E, oE, pe, oe)
    # compression noise of v, and s^T * (compression noise of u)
    pv, ov = comp_err_pmf(q, dv); E, oE = conv(E, oE, pv, ov)
    pu, ou = comp_err_pmf(q, du); ps, os_ = dfp.cbd(eta)
    prod = {}
    for i, a in enumerate(range(-os_, os_ + 1)):
        for j, b in enumerate(range(-ou, len(pu) - ou)):
            prod[a * b] = prod.get(a * b, 0) + ps[i] * pu[j]
    off = max(abs(v) for v in prod); arr = np.zeros(2 * off + 1)
    for v, p in prod.items(): arr[v + off] += p
    su, osu = dfp.conv_pow(arr, off, k * 511)
    su, osu = reflect(su, osu)
    E, oE = conv(E, oE, su, osu)
    idx = np.arange(len(E)) - oE; t = E[np.abs(idx) >= q // 4].sum()
    return log2(t) + 8

def table():
    print("k  q     du dv  ct bytes  log2 delta")
    for k, q in ((2, 2531), (3, 3329), (4, 3557)):
        for du, dv in ((10, 4), (10, 5), (11, 5), (11, 6), (12, 12)):
            ct = 32 * k * du + 32 * dv
            print(f"{k}  {q}  {du:2d} {dv:2d}   {ct:5d}     {delta_compressed(k, q, du, dv):7.1f}")

# ---- why not a modulus with a native NTT (q = 1 mod 512)? ----
def cbd_dist(eta): return {i - eta: comb(2 * eta, i) / 4**eta for i in range(2 * eta + 1)}
def log2delta_chernoff(k, eta, q):
    c = cbd_dist(eta); pr = {}
    for a, pa in c.items():
        for b, pb in c.items(): pr[a * b] = pr.get(a * b, 0) + pa * pb
    S = np.linspace(0.0005, 0.3, 3000)
    mp_ = np.log(sum(p * np.exp(S * v) for v, p in pr.items())); mc = np.log(sum(p * np.exp(S * v) for v, p in c.items()))
    val = (-S * (q // 4) + 2 * k * 511 * mp_ + mc).min()
    return (log(512) + val) / log(2)
def usvp_beta(n, q, v):
    B = np.arange(60, 2200, dtype=float)
    ld = np.log(((np.pi * B) ** (1 / B) * B / (2 * np.pi * np.e)) ** (1 / (2 * (B - 1))))
    ms = np.arange(max(8, n // 2), 2 * n + 1, 8, dtype=float)[:, None]
    d = ms + n + 1; nv = np.sqrt(ms * v + n * v + 1)
    ok = np.log(np.sqrt(B[None, :] / d) * nv) <= (2 * B[None, :] - d - 1) * ld[None, :] + (ms / d) * log(q)
    first = np.where(ok.any(axis=1), ok.argmax(axis=1), 10**6)
    return int(B[first.min()]) if first.min() < 10**6 else 9999
def native_ntt_modulus():
    q, k = 12289, 2
    print("\nq = 12289 (512 | q-1, ord_257(q) = 256), k = 2: smallest eta reaching uSVP beta >= 398 (CLH-512 target)")
    for eta in range(2, 41):
        b = usvp_beta(256 * k, q, eta / 2)
        if b >= 398:
            print(f"eta = {eta}: beta_uSVP = {b}, log2 delta (Chernoff) = {log2delta_chernoff(k, eta, q):.0f}"); break
if __name__ == "__main__":
    table(); native_ntt_modulus()
