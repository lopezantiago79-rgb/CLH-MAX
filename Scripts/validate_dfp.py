"""Monte Carlo validation of the exact-convolution model for the decryption error coefficient E_i.
Samples E = e^T r - s^T e1 + e2 in Z[X]/Phi_257 (eta = 2) and compares the empirical tail
P(|E_i| >= t) with the exact distribution computed by scripts/dfp.py (independence heuristic).
Usage: python3 validate_dfp.py   (needs numpy; ~70 s)"""
import numpy as np, time
import dfp          # scripts/dfp.py in the same folder
rng=np.random.default_rng(12345)
def cbd2(shape): return (rng.integers(0,2,shape)+rng.integers(0,2,shape)-rng.integers(0,2,shape)-rng.integers(0,2,shape)).astype(np.float64)
def ring_mul_batch(a,b):
    """a,b float arrays (...,256) of small ints; exact product mod Phi_257 over Z (no q)."""
    fa=np.fft.rfft(a,512,axis=-1); fb=np.fft.rfft(b,512,axis=-1)
    c=np.rint(np.fft.irfft(fa*fb,512,axis=-1)[...,:511]).astype(np.int64)
    p=np.zeros(c.shape[:-1]+(257,),dtype=np.int64)
    p+=c[...,:257]; p[...,:254]+=c[...,257:511]
    return p[...,:256]-p[...,256:257]
def sample_E(k,T):
    e=cbd2((T,k,256)); r=cbd2((T,k,256)); s=cbd2((T,k,256)); e1=cbd2((T,k,256)); e2=cbd2((T,256))
    E=ring_mul_batch(e,r).sum(axis=1)-ring_mul_batch(s,e1).sum(axis=1)+e2.astype(np.int64)
    return E
def predicted_tail(k,ts):
    pa,oa=dfp.prod_pmf(2,2); pb,ob=dfp.prod_pmf(2,2)
    d1,o1=dfp.conv_pow(pa,oa,k*511); d2,o2=dfp.conv_pow(pb,ob,k*511)
    d=np.convolve(d1,d2); o=o1+o2; p2,oo=dfp.cbd(2); d=np.convolve(d,p2); o+=oo
    idx=np.arange(len(d))-o
    return {t:d[np.abs(idx)>=t].sum() for t in ts}
for k,T in ((2,300000),(4,150000)):
    t0=time.time(); counts=None; tot=0
    ts=list(range(int(1.0*np.sqrt(1022*k+1)*2.0),int(np.sqrt(1022*k+1)*4.6),max(1,int(np.sqrt(1022*k+1)/4))))
    cnt={t:0 for t in ts}
    chunk=3000
    for _ in range(T//chunk):
        E=np.abs(sample_E(k,chunk)); tot+=E.size
        for t in ts: cnt[t]+=int((E>=t).sum())
    pred=predicted_tail(k,ts)
    print(f"\nk={k}  samples={tot:.2e}  sigma_E={np.sqrt(1022*k+1):.1f}  ({time.time()-t0:.0f}s)")
    print("   t   empirical        predicted     ratio  (events)")
    for t in ts:
        emp=cnt[t]/tot; ratio=emp/pred[t] if pred[t]>0 else float('nan')
        print(f"{t:5d}  {emp:.3e}   {pred[t]:.3e}   {ratio:5.2f}   {cnt[t]}")
