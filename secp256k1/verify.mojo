from decimojo import BigInt
from .sign import (
    B,
    CURVE_N,
    FIELD_P,
    generator_point,
    point_add,
    point_mul,
    mod_inv,
    mod_positive,
    bytes_to_int_be,
    Point,
)
from .sha256 import sha256_bytes
from .curve import point_is_on_curve

fn ecdsa_verify(
    pub_key_uncompressed: List[Int],
    msg: List[Int],
    r: BigInt,
    s: BigInt,
) raises -> Bool:
    if len(pub_key_uncompressed) != 65 or pub_key_uncompressed[0] != 4:
        raise Error("Invalid uncompressed public key format")

    var qx = bytes_to_int_be(pub_key_uncompressed[1:33])
    var qy = bytes_to_int_be(pub_key_uncompressed[33:65])
    var Q = Point()
    Q.infinity = False
    Q.x = mod_positive(qx, FIELD_P)
    Q.y = mod_positive(qy, FIELD_P)

    if not point_is_on_curve(Q):
        return False

    if r <= 0 or r >= CURVE_N or s <= 0 or s >= CURVE_N:
        return False

    var z = bytes_to_int_be(sha256_bytes(msg))
    var w = mod_inv(s, CURVE_N)
    var u1 = mod_positive(mod_positive(z, CURVE_N) * mod_positive(w, CURVE_N), CURVE_N)
    var u2 = mod_positive(mod_positive(r, CURVE_N) * mod_positive(w, CURVE_N), CURVE_N)

    var p1 = point_mul(u1, generator_point())
    var p2 = point_mul(u2, Q)
    var R = point_add(p1, p2)

    if R.infinity:
        return False

    return mod_positive(R.x, CURVE_N) == r
