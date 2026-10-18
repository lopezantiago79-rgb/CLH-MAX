# Message-recovery (encryption-side) instances: secret r, errors (e1, e2); n = k*256, m = (k+1)*256.
# Run in the same estimator environment and cost model as the key-recovery runs.
from estimator import *
CBD = ND.CenteredBinomial
sets = [
    # name,          k, q,    eta_s(r), eta_e(e1,e2)
    ("CLH-512-q2531",  2, 2531, 2, 2),
    ("CLH-768-q3329",  3, 3329, 2, 2),
    ("CLH-1024-q3557", 4, 3557, 2, 2),
    ("ML-KEM-512",     2, 3329, 3, 2),   # r ~ psi_3, e1,e2 ~ psi_2
    ("ML-KEM-768",     3, 3329, 2, 2),
    ("ML-KEM-1024",    4, 3329, 2, 2),
]
for name, k, q, es, ee in sets:
    p = LWE.Parameters(n=256*k, q=q, Xs=CBD(es), Xe=CBD(ee), m=256*(k+1), tag=name)
    print(name); print(LWE.estimate(p))
