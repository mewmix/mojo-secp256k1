from decimojo import BigInt
from .sign import (
    CURVE_N,
    HALF_CURVE_N,
    bytes_to_int_be,
    int_to_bytes32_be,
    generator_point,
    point_mul,
    mod_inv,
    mod_positive,
    SigCompact,
)

fn ecdsa_sign_keccak_with_k(msg32: List[Int], seckey32: List[Int], k_int: BigInt) raises -> SigCompact:
    if len(msg32) != 32:
        raise Error("message must be 32 bytes")
    if len(seckey32) != 32:
        raise Error("secret key must be 32 bytes")

    var priv = mod_positive(bytes_to_int_be(seckey32), CURVE_N)
    if priv.is_zero():
        raise Error("invalid secret key (zero)")

    var e = mod_positive(bytes_to_int_be(msg32), CURVE_N)
    var k = mod_positive(k_int, CURVE_N)

    if k.is_zero():
        raise Error("k cannot be zero")

    var R = point_mul(k, generator_point())
    if R.infinity:
        raise Error("R is point at infinity")

    var r = mod_positive(R.x, CURVE_N)
    if r.is_zero():
        raise Error("r is zero")

    var kinv = mod_inv(k, CURVE_N)
    var s = mod_positive(kinv * mod_positive(e + (r * priv), CURVE_N), CURVE_N)
    if s.is_zero():
        raise Error("s is zero")

    var recid = 0
    if R.y % BigInt(2) != BigInt(0):
        recid = 1

    if s > HALF_CURVE_N:
        recid ^= 1
        s = CURVE_N - s

    var sig = SigCompact()
    sig.r = int_to_bytes32_be(r)
    sig.s = int_to_bytes32_be(s)
    sig.v = 27 + recid
    return sig.copy()
