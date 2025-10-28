"""Pure Mojo ECDSA public-key recovery on secp256k1 (Ethereum v in {27,28})."""

from decimojo import BigInt
from .sign import (
    FIELD_P, CURVE_N, B, GEN_X, GEN_Y,
    mod_positive, mod_pow, mod_inv,
    Point, point_from_xy, point_infinity, point_neg,
    point_add, point_mul, generator_point,
    bytes_to_int_be, int_to_bytes32_be
)

@always_inline
fn parity(b: BigInt) raises -> Int:
    var two = BigInt(2)
    var m = b % two
    return Int(m)

fn sqrt_mod_p(a: BigInt) raises -> BigInt:
    # For secp256k1: p % 4 == 3 => sqrt = a^((p+1)/4) mod p
    var exp = (FIELD_P + BigInt(1)) // BigInt(4)
    return mod_positive(mod_pow(mod_positive(a, FIELD_P), exp, FIELD_P), FIELD_P)

fn decompress_point_from_rx(r: BigInt, v: Int) raises -> Point:
    # Recreate R from x=r and y chosen by v parity (27/28 => 0/1)
    var x = mod_positive(r, FIELD_P)
    if x.is_zero():
        raise Error("invalid r (zero)")

    # y^2 = x^3 + 7 (mod p)
    var rhs = mod_positive(mod_positive(x * x % FIELD_P * x, FIELD_P) + B, FIELD_P)
    var y = sqrt_mod_p(rhs)

    # Choose y whose LSB matches (v-27) & 1
    var ybit = (v - 27) & 1
    try:
        var p = parity(y)
        if p != ybit:
            y = mod_positive(FIELD_P - y, FIELD_P)
    except:
        raise

    return point_from_xy(x, y)

fn check_on_curve(p: Point) raises:
    if p.infinity:
        raise Error("point at infinity")
    # Verify y^2 == x^3 + 7 (mod p) – defensive; cheap enough
    var lhs = mod_positive(p.y * p.y, FIELD_P)
    var rhs = mod_positive(mod_positive(p.x * p.x % FIELD_P * p.x, FIELD_P) + B, FIELD_P)
    if lhs != rhs:
        raise Error("not on curve")

fn ecdsa_recover_keccak(
    msg32: List[Int], r_bytes: List[Int], s_bytes: List[Int], v: Int
) raises -> Point:

    if len(msg32) != 32 or len(r_bytes) != 32 or len(s_bytes) != 32:
        raise Error("lengths must be 32")

    var e = mod_positive(bytes_to_int_be(msg32), CURVE_N)
    var r = mod_positive(bytes_to_int_be(r_bytes), CURVE_N)
    var s = mod_positive(bytes_to_int_be(s_bytes), CURVE_N)

    # Check v is valid (Ethereum: 27 or 28)
    if v != 27 and v != 28:
        raise Error("invalid recovery id v")

    # Check r, s in [1, n-1]
    if r.is_zero() or r >= CURVE_N:
        raise Error("invalid signature scalar r")
    if s.is_zero() or s >= CURVE_N:
        raise Error("invalid signature scalar s")

    # Enforce low-s (non-canonical signatures)
    var HALF_CURVE_N = CURVE_N // BigInt(2)
    if s > HALF_CURVE_N:
        raise Error("non-canonical signature: s > n/2")

    # Optionally: reject all-zeros message (policy, not ECDSA spec)
    var all_zeros = True
    for b in msg32:
        if b != 0:
            all_zeros = False
            break
    if all_zeros:
        raise Error("message is all zeros (adversarial)")

    # 1) Recover R from (r,v)
    var R = decompress_point_from_rx(r, v)
    check_on_curve(R)

    # 2) Q = r^-1 * (s*R - e*G)
    var rinv = mod_inv(r, CURVE_N)
    var sR = point_mul(s, R)
    var eG = point_mul(e, generator_point())
    var sR_minus_eG = point_add(sR, point_neg(eG))
    if sR_minus_eG.infinity:
        raise Error("sR - eG is infinity")
    var Q = point_mul(rinv, sR_minus_eG)

    check_on_curve(Q)
    return Q

# Utility: compare 64-byte uncompressed (x||y) encodings
fn pub_uncompressed_xy(p: Point) raises -> List[Int]:
    var out = [0] * 64
    var xb = int_to_bytes32_be(p.x)
    var yb = int_to_bytes32_be(p.y)
    @parameter
    for i in range(32):
        out[i] = xb[i] & 0xFF
        out[32 + i] = yb[i] & 0xFF
    return out.copy()
