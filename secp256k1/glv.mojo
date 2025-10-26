"""GLV endomorphism constants and decomposition stubs for secp256k1."""

from .sc import Sc

# TODO(perf): real constants for λ and lattice basis (μ's)
var LAMBDA: Sc = Sc()   # placeholder

struct GlvParts:
    var k1: Sc
    var k2: Sc
    fn __init__(self):
        self.k1 = Sc()
        self.k2 = Sc()

fn glv_decompose(k: Sc) -> GlvParts:
    # TODO(perf): constant-time nearest-plane decomposition into (k1,k2)
    var out = GlvParts()
    return out
