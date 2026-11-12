"""One batch for the lattice-estimator (open problems B and C).  Run in the same environment and with the same call
as before (LWE.estimate, default settings).  Key recovery: secret and error psi_eta1, m = n = 256k.  Message recovery:
secret r ~ psi_eta1, errors (e1, e2) ~ psi_eta2, n = 256k, m = 256(k+1).
Reference (weakest ML-KEM instance, dual hybrid, log2 ops): ML-KEM-512 136.6, ML-KEM-768 196.4, ML-KEM-1024 262.3."""
from estimator import *
CBD = ND.CenteredBinomial
# (label, k, q, eta1, eta2, which instances)
batch = [
    # B: missing message-recovery runs and the k=4 alternative modulus (symmetric noise eta = 2)
    ("B CLH-512  q=2663", 2, 2663, 2, 2, ("message",)),
    ("B CLH-1024 q=3617", 4, 3617, 2, 2, ("message",)),
    ("B CLH-1024 q=3643", 4, 3643, 2, 2, ("key", "message")),
    # C: asymmetric noise shortlist (smallest valid q with rigorous log2 delta <= -131)
    ("C k=2 eta1=2 eta2=1 q=2293", 2, 2293, 2, 1, ("key", "message")),
    ("C k=2 eta1=3 eta2=1 q=3301", 2, 3301, 3, 1, ("key", "message")),
    ("C k=2 eta1=3 eta2=2 q=3631", 2, 3631, 3, 2, ("key", "message")),
    ("C k=3 eta1=2 eta2=1 q=2789", 3, 2789, 2, 1, ("key", "message")),
    ("C k=4 eta1=2 eta2=1 q=3167", 4, 3167, 2, 1, ("key", "message")),
]
for label, k, q, e1, e2, kinds in batch:
    for kind in kinds:
        n = 256 * k
        if kind == "key": p = LWE.Parameters(n=n, q=q, Xs=CBD(e1), Xe=CBD(e1), m=n, tag=label)
        else:             p = LWE.Parameters(n=n, q=q, Xs=CBD(e1), Xe=CBD(e2), m=256 * (k + 1), tag=label)
        print(f"=== {label} ({kind}) ==="); print(LWE.estimate(p))
