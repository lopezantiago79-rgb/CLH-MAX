# Run inside a lattice-estimator checkout: https://github.com/malb/lattice-estimator
# Record the commit hash (git rev-parse HEAD) and use the SAME call/cost model for all rows.
from estimator import *
CBD = ND.CenteredBinomial
sets = [
    # name, n, eta_s, eta_e
    ("CLH-MAX-512",  512, 2, 2), ("CLH-MAX-768",  768, 2, 2), ("CLH-MAX-1024", 1024, 2, 2),
    ("ML-KEM-512",   512, 3, 3), ("ML-KEM-768",   768, 2, 2), ("ML-KEM-1024",  1024, 2, 2),
]  # ML-KEM key recovery: s and e both ~ CBD(eta1); eta1 = 3 only for ML-KEM-512
for name, n, es, ee in sets:
    p = LWE.Parameters(n=n, q=3329, Xs=CBD(es), Xe=CBD(ee), m=n, tag=name)
    print(name); print(LWE.estimate(p))
