"""Deterministic Ethereum-style ECDSA signing using DeciMojo BigInt."""

from decimojo import BigInt
from decimojo.bigint.bigint import BigUInt
from keccak import keccak256_bytes
from .rfc6979 import rfc6979_sha256


fn make_bigint(var words: List[UInt32]) -> BigInt:
    var magnitude = BigUInt()
    magnitude.words = words^
    var out = BigInt()
    out.magnitude = magnitude
    out.sign = False
    return out


alias FIELD_P = make_bigint(
    List[UInt32](
        UInt32(834671663),
        UInt32(584007908),
        UInt32(564039457),
        UInt32(984665640),
        UInt32(907853269),
        UInt32(985008687),
        UInt32(195423570),
        UInt32(89237316),
        UInt32(115792),
    )
)
alias CURVE_N = make_bigint(
    List[UInt32](
        UInt32(161494337),
        UInt32(163141518),
        UInt32(904382605),
        UInt32(564279074),
        UInt32(907852837),
        UInt32(985008687),
        UInt32(195423570),
        UInt32(89237316),
        UInt32(115792),
    )
)
alias B = BigInt(7)
alias TWO_POW_256 = make_bigint(
    List[UInt32](
        UInt32(129639936),
        UInt32(584007913),
        UInt32(564039457),
        UInt32(984665640),
        UInt32(907853269),
        UInt32(985008687),
        UInt32(195423570),
        UInt32(89237316),
        UInt32(115792),
    )
)
alias HALF_CURVE_N = make_bigint(
    List[UInt32](
        UInt32(80747168),
        UInt32(581570759),
        UInt32(452191302),
        UInt32(782139537),
        UInt32(953926418),
        UInt32(492504343),
        UInt32(97711785),
        UInt32(44618658),
        UInt32(57896),
    )
)

alias GEN_X = make_bigint(
    List[UInt32](
        UInt32(116729240),
        UInt32(187360389),
        UInt32(594175500),
        UInt32(603453777),
        UInt32(534326250),
        UInt32(718895168),
        UInt32(343669578),
        UInt32(263022277),
        UInt32(55066),
    )
)
alias GEN_Y = make_bigint(
    List[UInt32](
        UInt32(337482424),
        UInt32(904335757),
        UInt32(243275938),
        UInt32(273380659),
        UInt32(43184471),
        UInt32(85130507),
        UInt32(816978083),
        UInt32(510020758),
        UInt32(32670),
    )
)


fn mod_positive(value: BigInt, modulus: BigInt) raises -> BigInt:
    var r = value.truncate_modulo(modulus)
    if r < BigInt(0):
        r = r + modulus
    return r


fn mod_pow(base: BigInt, exp: BigInt, modulus: BigInt) raises -> BigInt:
    var res = BigInt(1)
    var b = base
    var e = exp
    while e > BigInt(0):
        if e % BigInt(2) == BigInt(1):
            res = mod_positive(res * b, modulus)
        b = mod_positive(b * b, modulus)
        e = e // BigInt(2)
    return res


fn mod_inv(value: BigInt, modulus: BigInt) raises -> BigInt:
    if modulus <= BigInt(0):
        raise Error("modulus must be positive")
    var val_mod = mod_positive(value, modulus)
    if val_mod.is_zero():
        raise Error("inverse does not exist")
    var exp = modulus - BigInt(2)
    return mod_pow(val_mod, exp, modulus)


struct Point(ImplicitlyCopyable, Movable):
    var x: BigInt
    var y: BigInt
    var infinity: Bool

    fn __init__(out self):
        self.x = BigInt(0)
        self.y = BigInt(0)
        self.infinity = True

struct JacobianPoint(ImplicitlyCopyable, Movable):
    var x: BigInt
    var y: BigInt
    var z: BigInt
    var infinity: Bool

    fn __init__(out self):
        self.x = BigInt(0)
        self.y = BigInt(0)
        self.z = BigInt(0)
        self.infinity = True

struct SigCompact(Copyable, Movable):
    var r: List[Int]
    var s: List[Int]
    var v: Int

    fn __init__(out self):
        self.r = [0] * 32
        self.s = [0] * 32
        self.v = 0



fn affine_to_jacobian(p: Point) -> JacobianPoint:
    var res = JacobianPoint()
    if p.infinity:
        res.infinity = True
    else:
        res.x = p.x
        res.y = p.y
        res.z = BigInt(1)
        res.infinity = False
    return res

fn jacobian_to_affine(p: JacobianPoint) raises -> Point:
    if p.infinity:
        return point_infinity()
    
    var z_inv = mod_inv(p.z, FIELD_P)
    var z_inv_sq = mod_positive(z_inv * z_inv, FIELD_P)
    var x = mod_positive(p.x * z_inv_sq, FIELD_P)
    var y = mod_positive(p.y * z_inv_sq * z_inv, FIELD_P)
    return point_from_xy(x, y)

fn point_double_jacobian(p: JacobianPoint) raises -> JacobianPoint:
    if p.infinity or p.y.is_zero():
        var res = JacobianPoint()
        res.infinity = True
        return res

    var y2 = mod_positive(p.y * p.y, FIELD_P)
    var s = mod_positive(BigInt(4) * p.x * y2, FIELD_P)
    var m = mod_positive(BigInt(3) * p.x * p.x, FIELD_P)
    var x = mod_positive(m * m - BigInt(2) * s, FIELD_P)
    var y = mod_positive(m * (s - x) - BigInt(8) * y2 * y2, FIELD_P)
    var z = mod_positive(BigInt(2) * p.y * p.z, FIELD_P)
    
    var res = JacobianPoint()
    res.x = x
    res.y = y
    res.z = z
    res.infinity = False
    return res

fn point_add_jacobian(p1: JacobianPoint, p2: JacobianPoint) raises -> JacobianPoint:
    if p1.infinity:
        return p2
    if p2.infinity:
        return p1

    var z1z1 = mod_positive(p1.z * p1.z, FIELD_P)
    var z2z2 = mod_positive(p2.z * p2.z, FIELD_P)
    var u1 = mod_positive(p1.x * z2z2, FIELD_P)
    var u2 = mod_positive(p2.x * z1z1, FIELD_P)
    var s1 = mod_positive(p1.y * z2z2 * p2.z, FIELD_P)
    var s2 = mod_positive(p2.y * z1z1 * p1.z, FIELD_P)

    if u1 == u2:
        if s1 != s2:
            var res = JacobianPoint()
            res.infinity = True
            return res
        else:
            return point_double_jacobian(p1)

    var h = u2 - u1
    var r = s2 - s1
    var h2 = mod_positive(h * h, FIELD_P)
    var h3 = mod_positive(h2 * h, FIELD_P)
    var u1_h2 = mod_positive(u1 * h2, FIELD_P)
    
    var x = mod_positive(r * r - h3 - BigInt(2) * u1_h2, FIELD_P)
    var y = mod_positive(r * (u1_h2 - x) - mod_positive(s1 * h3, FIELD_P), FIELD_P)
    var z = mod_positive(h * p1.z * p2.z, FIELD_P)

    var res = JacobianPoint()
    res.x = x
    res.y = y
    res.z = z
    res.infinity = False
    return res

fn point_infinity() -> Point:
    var p = Point()
    p.infinity = True
    return p^


fn point_from_xy(x: BigInt, y: BigInt) raises -> Point:
    var p = Point()
    p.infinity = False
    p.x = mod_positive(x, FIELD_P)
    p.y = mod_positive(y, FIELD_P)
    return p^


fn point_neg(p: Point) raises -> Point:
    if p.infinity:
        return p
    return point_from_xy(p.x, -p.y)



fn point_double(p: Point) raises -> Point:
    if p.infinity:
        return p
    if p.y.is_zero():
        return point_infinity()

    var numerator = mod_positive(BigInt(3) * p.x * p.x, FIELD_P)
    var denominator = mod_inv(BigInt(2) * p.y, FIELD_P)
    var lam = mod_positive(numerator * denominator, FIELD_P)
    var xr = mod_positive(lam * lam - BigInt(2) * p.x, FIELD_P)
    var yr = mod_positive(lam * (p.x - xr) - p.y, FIELD_P)
    return point_from_xy(xr, yr)


fn point_add(a: Point, b: Point) raises -> Point:
    if a.infinity:
        return b
    if b.infinity:
        return a

    if a.x == b.x and a.y != b.y:
        return point_infinity()
    if a.x == b.x and a.y == b.y:
        return point_double(a)

    var numerator = mod_positive(b.y - a.y, FIELD_P)
    var denominator = mod_inv(b.x - a.x, FIELD_P)
    var lam = mod_positive(numerator * denominator, FIELD_P)
    var xr = mod_positive(lam * lam - a.x - b.x, FIELD_P)
    var yr = mod_positive(lam * (a.x - xr) - a.y, FIELD_P)
    return point_from_xy(xr, yr)


fn point_mul(k: BigInt, base: Point) raises -> Point:
    var scalar = mod_positive(k, CURVE_N)
    
    if base.infinity or scalar.is_zero():
        return point_infinity()

    var base_j = affine_to_jacobian(base)
    var result_j = JacobianPoint()
    result_j.infinity = True

    var naf = List[Int]()
    var k_naf = scalar
    while k_naf > BigInt(0):
        if k_naf % BigInt(2) == BigInt(1):
            var z = 2 - Int(k_naf % BigInt(4))
            naf.append(z)
            k_naf = k_naf - BigInt(z)
        else:
            naf.append(0)
        k_naf = k_naf // BigInt(2)

    var neg_base_j = affine_to_jacobian(point_neg(base))

    for i in range(len(naf) - 1, -1, -1):
        result_j = point_double_jacobian(result_j)
        if naf[i] == 1:
            result_j = point_add_jacobian(result_j, base_j)
        elif naf[i] == -1:
            result_j = point_add_jacobian(result_j, neg_base_j)

    return jacobian_to_affine(result_j)


fn generator_point() -> Point:
    var p = Point()
    p.infinity = False
    p.x = GEN_X
    p.y = GEN_Y
    return p^

fn pubkey_from_seckey(seckey32: List[Int]) raises -> Point:
    if len(seckey32) != 32:
        raise Error("secret key must be 32 bytes")
    var priv = mod_positive(bytes_to_int_be(seckey32), CURVE_N)
    if priv.is_zero():
        raise Error("invalid secret key (zero)")
    return point_mul(priv, generator_point())

fn pubkey_serialize_uncompressed_xy(p: Point) raises -> List[Int]:
    if p.infinity:
        raise Error("cannot serialize point at infinity")
    var out = [0] * 64
    var xb = int_to_bytes32_be(p.x)
    var yb = int_to_bytes32_be(p.y)
    @parameter
    for i in range(32):
        out[i] = xb[i] & 0xFF
        out[32 + i] = yb[i] & 0xFF
    return out.copy()


fn bytes_to_int_be(data: List[Int]) -> BigInt:
    var acc = BigInt(0)
    for b in data:
        acc = acc * BigInt(256) + BigInt(b & 0xFF)
    return acc


fn int_to_bytes32_be(value: BigInt) raises -> List[Int]:
    var out = [0] * 32
    var v = mod_positive(value, TWO_POW_256)
    for idx in range(31, -1, -1):
        var byte = v % BigInt(256)
        out[idx] = Int(byte)
        v = v // BigInt(256)
    return out.copy()


fn eth_personal_hash(msg: List[Int]) -> List[Int]:
    var prefix = "\x19Ethereum Signed Message:\n" + String(len(msg))
    var data = [0] * (len(prefix) + len(msg))
    var i = 0
    for cp in prefix.codepoints():
        data[i] = Int(cp)
        i += 1
    for b in msg:
        data[i] = b & 0xFF
        i += 1
    var digest = keccak256_bytes(data, len(data))
    return digest.copy()


fn ecdsa_sign_keccak(msg32: List[Int], seckey32: List[Int]) raises -> SigCompact:
    if len(msg32) != 32:
        raise Error("message must be 32 bytes")
    if len(seckey32) != 32:
        raise Error("secret key must be 32 bytes")

    var priv = mod_positive(bytes_to_int_be(seckey32), CURVE_N)
    if priv.is_zero():
        raise Error("invalid secret key (zero)")

    var e = mod_positive(bytes_to_int_be(msg32), CURVE_N)
    var e_bytes = int_to_bytes32_be(e)
    var nonce = rfc6979_sha256(e_bytes, seckey32)
    var attempts = 0

    while attempts < 1024:
        var k_bytes = nonce.next()
        attempts += 1
        var k = mod_positive(bytes_to_int_be(k_bytes), CURVE_N)

        if k.is_zero():
            nonce.reseed()
            continue

        var R = point_mul(k, generator_point())
        if R.infinity:
            nonce.reseed()
            continue

        var r = mod_positive(R.x, CURVE_N)
        if r.is_zero():
            nonce.reseed()
            continue

        var kinv = mod_inv(k, CURVE_N)
        var s = mod_positive(kinv * mod_positive(e + (r * priv), CURVE_N), CURVE_N)
        if s.is_zero():
            nonce.reseed()
            continue

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

    raise Error("failed to generate a valid nonce")
