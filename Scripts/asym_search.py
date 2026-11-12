"""Open problem (ii)/(C): asymmetric noise (eta1 for s, e, r; eta2 for e1, e2).  For each (k, eta1, eta2) the smallest
valid modulus q whose RIGOROUS (Chernoff, float64) bound gives log2 delta <= -131 (3 bits of margin).  The security
column is the calibrated uSVP model for the KEY instance (symmetric noise eta1, where the model is exact); the
message-recovery instance with asymmetric noise is NOT modelled (the model does not reproduce the estimator there),
so the shortlist must be checked with the lattice-estimator (estimate_batch.py).   Usage: python3 asym_search.py"""
import rigorous_dfp as R, dfp
from compression_dfp import usvp_beta
def valid_moduli(lo=2000, hi=4300):
    return [q for q in range(lo, hi) if R.isprime(q) and q != 257 and R.order257(q) == 256]
if __name__ == "__main__":
    Q = valid_moduli()
    print("k  eta1 eta2   q_min   rigorous log2delta   beta_uSVP (key instance, model)   (ML-KEM key beta: 406 / 624 / 874)")
    for k in (2, 3, 4):
        for eta1 in (1, 2, 3):
            for eta2 in (1, 2, 3):
                for q in Q:
                    d = R.rigorous_log2delta_asym(k, eta1, eta2, q)
                    if d <= -131:
                        print(f"{k}   {eta1}    {eta2}     {q}    {d:8.1f}              {usvp_beta(256 * k, q, eta1 / 2)}")
                        break
                else:
                    print(f"{k}   {eta1}    {eta2}     none below {Q[-1]}")
