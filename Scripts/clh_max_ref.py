"""
CLH-MAX reference implementation (Python/numpy).  NOT constant-time, NOT for production use.
Purpose: check that the scheme of the paper is correct end to end (PKE + FO transform with implicit
rejection) and that the ring multiplication of the paper (fold + subtract) is right.
Usage: python3 clh_max_ref.py      (runs a self-test)
"""
import hashlib, numpy as np, os
N = 256
PARAMS = {512: (2, 2531), 768: (3, 3329), 1024: (4, 3557)}       # name: (k, q)

# ---------- ring arithmetic in Z_q[X]/Phi_257 ----------
def ring_mul(a, b, q):
    """Fold method: cyclic convolution mod X^257-1, then subtract p_256 (paper, Section 3)."""
    c = np.convolve(a.astype(np.int64), b.astype(np.int64))
    p = np.zeros(257, dtype=np.int64)
    p[:257] += c[:257]; p[:254] += c[257:511]
    return (p[:256] - p[256]) % q

PA = 469762049                       # 7*2^26+1; 512 | PA-1.  Auxiliary prime for NTT-based products.
def _ntt(x, inv=False):
    n = len(x); a = np.array(x, dtype=np.int64) % PA; j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit: j ^= bit; bit >>= 1
        j |= bit
        if i < j: a[i], a[j] = a[j], a[i]
    length = 2
    while length <= n:
        w = pow(pow(3, (PA - 1) // 512, PA), 512 // length, PA)
        if inv: w = pow(w, PA - 2, PA)
        half = length // 2; ws = np.array([pow(w, t, PA) for t in range(half)], dtype=np.int64)
        for s in range(0, n, length):
            u = a[s:s+half].copy(); v = (a[s+half:s+length] * ws) % PA
            a[s:s+half] = (u + v) % PA; a[s+half:s+length] = (u - v) % PA
        length <<= 1
    return (a * pow(n, PA - 2, PA)) % PA if inv else a
def ring_mul_ntt(a_uniform, b_small, q):
    """Same product via an NTT over the auxiliary prime PA. Exact because one operand is small:
    |coeff| <= 256*(q/2)*eta << PA/2. Every product in CLH-MAX has one small operand."""
    a = np.where(a_uniform > q // 2, a_uniform - q, a_uniform).astype(np.int64)
    z = np.zeros(256, dtype=np.int64)
    c = _ntt((_ntt(np.concatenate([a, z])) * _ntt(np.concatenate([b_small.astype(np.int64), z]))) % PA, True)
    c = np.where(c > PA // 2, c - PA, c)
    p = np.zeros(257, dtype=np.int64); p[:257] += c[:257]; p[:254] += c[257:511]
    return (p[:256] - p[256]) % q

# ---------- sampling (SHAKE-based; reference quality) ----------
def _xof(seed, nonce, nbytes):
    return hashlib.shake_256(seed + bytes([nonce])).digest(nbytes)
def cbd2(seed, nonce, count=N):
    bits = np.unpackbits(np.frombuffer(_xof(seed, nonce, count // 2 + 1), dtype=np.uint8))[:4 * count].reshape(count, 4)
    return (bits[:, 0].astype(np.int64) + bits[:, 1] - bits[:, 2] - bits[:, 3])
def expand_matrix(rho, k, q):
    out = hashlib.shake_128(rho).digest(k * k * N * 8); vals = []; i = 0
    while len(vals) < k * k * N:
        if i + 3 > len(out): out = hashlib.shake_128(rho).digest(len(out) * 2)
        b0, b1, b2 = out[i], out[i+1], out[i+2]; i += 3
        for v in (b0 | ((b1 & 15) << 8), (b1 >> 4) | (b2 << 4)):
            if v < q and len(vals) < k * k * N: vals.append(v)
    return np.array(vals, dtype=np.int64).reshape(k, k, N)

# ---------- PKE ----------
def pke_keygen(k, q, d):
    rho, sigma = d[:32], d[32:64]
    A = expand_matrix(rho, k, q)
    s = [cbd2(sigma, j) for j in range(k)]; e = [cbd2(sigma, k + j) for j in range(k)]
    t = [(sum(ring_mul(A[i, j], s[j] % q, q) for j in range(k)) + e[i]) % q for i in range(k)]
    return (rho, t), s
def pke_enc(pk, m_bits, coins, k, q):
    rho, t = pk; A = expand_matrix(rho, k, q)
    r = [cbd2(coins, j) for j in range(k)]; e1 = [cbd2(coins, k + j) for j in range(k)]; e2 = cbd2(coins, 2 * k)
    u = [(sum(ring_mul(A[j, i], r[j] % q, q) for j in range(k)) + e1[i]) % q for i in range(k)]   # A^T r + e1
    v = (sum(ring_mul(t[j], r[j] % q, q) for j in range(k)) + e2 + ((q + 1) // 2) * m_bits) % q
    return u, v
def pke_dec(s, ct, k, q):
    u, v = ct
    w = (v - sum(ring_mul(u[j], s[j] % q, q) for j in range(k))) % q
    return ((4 * w >= q) & (4 * w < 3 * q)).astype(np.int64)

# ---------- KEM (FO with implicit rejection, as in the paper) ----------
H = lambda x: hashlib.sha3_256(x).digest()
G = lambda x: hashlib.shake_256(x).digest(64)
def ct_bytes(ct): return b"".join(x.astype(np.int16).tobytes() for x in ct[0]) + ct[1].astype(np.int16).tobytes()
def kem_keygen(name):
    k, q = PARAMS[name]; pk, s = pke_keygen(k, q, os.urandom(64)); z = os.urandom(32)
    pkb = pk[0] + b"".join(x.astype(np.int16).tobytes() for x in pk[1])
    return (pk, pkb), (s, pk, H(pkb), z)
def kem_encaps(name, pkfull):
    k, q = PARAMS[name]; pk, pkb = pkfull; m = os.urandom(32)
    Kbar_r = G(m + H(pkb)); Kbar, r = Kbar_r[:32], Kbar_r[32:]
    ct = pke_enc(pk, np.unpackbits(np.frombuffer(m, dtype=np.uint8)).astype(np.int64), r, k, q)
    return ct, H(Kbar + H(ct_bytes(ct)))
def kem_decaps(name, sk, ct):
    k, q = PARAMS[name]; s, pk, hpk, z = sk
    m = np.packbits(pke_dec(s, ct, k, q).astype(np.uint8)).tobytes()
    Kbar_r = G(m + hpk); Kbar, r = Kbar_r[:32], Kbar_r[32:]
    ct2 = pke_enc(pk, np.unpackbits(np.frombuffer(m, dtype=np.uint8)).astype(np.int64), r, k, q)
    return H((Kbar if ct_bytes(ct2) == ct_bytes(ct) else z) + H(ct_bytes(ct)))

if __name__ == "__main__":
    rng = np.random.default_rng(0)
    for name, (k, q) in PARAMS.items():
        a, b = rng.integers(0, q, N), rng.integers(-2, 3, N)
        assert np.array_equal(ring_mul(a, b % q, q), ring_mul_ntt(a, b, q)), "NTT product mismatch"
        pkfull, sk = kem_keygen(name); ok = rej = 0
        for _ in range(10):
            ct, K = kem_encaps(name, pkfull)
            ok += kem_decaps(name, sk, ct) == K
            bad = ([x.copy() for x in ct[0]], ct[1].copy()); bad[1][5] = (bad[1][5] + 700) % q
            rej += kem_decaps(name, sk, bad) != K
        pke_fail = 0
        for _ in range(100):
            pk, s = pke_keygen(k, q, os.urandom(64)); m = rng.integers(0, 2, N)
            pke_fail += int(not np.array_equal(pke_dec(s, pke_enc(pk, m, os.urandom(32), k, q), k, q), m))
        print(f"CLH-MAX-{name} (k={k}, q={q}): KEM roundtrips {ok}/10, tampered ciphertexts rejected {rej}/10, "
              f"PKE decryption failures {pke_fail}/100, NTT product == fold product: True")
