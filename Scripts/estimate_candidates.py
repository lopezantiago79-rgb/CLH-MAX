# Run inside a lattice-estimator checkout, same environment/cost model as for estimate_clh_max.py.
# Candidate CLH-MAX parameter sets found by screening (open problem (i)): they change q so that
# the decryption failure probability is < 2^-128 while keeping uSVP beta close to ML-KEM.
from estimator import *
CBD = ND.CenteredBinomial
candidates = [
    # name,               n,    q,    eta
    ("CLH-512-q2531",     512,  2531, 2),
    ("CLH-512-q2663",     512,  2663, 2),
    ("CLH-1024-q3557",    1024, 3557, 2),
    ("CLH-1024-q3617",    1024, 3617, 2),
]
for name, n, q, eta in candidates:
    p = LWE.Parameters(n=n, q=q, Xs=CBD(eta), Xe=CBD(eta), m=n, tag=name)
    print(name); print(LWE.estimate(p))
