"""Deterministic Ethereum-style ECDSA signing using DeciMojo BigInt."""

from decimojo import BigInt
from decimojo.bigint.bigint import BigUInt
from keccak import keccak256_bytes
from .rfc6979_keccak import rfc6979_keccak


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


fn mod_inv(value: BigInt, modulus: BigInt) raises -> BigInt:
    var t = BigInt(0)
    var new_t = BigInt(1)
    var r = modulus
    var new_r = mod_positive(value, modulus)

    if modulus <= BigInt(0):
        raise Error("modulus must be positive")
    if new_r.is_zero():
        raise Error("inverse does not exist")

    while not new_r.is_zero():
        var quotient = r // new_r
        var temp_t = t - quotient * new_t
        t = new_t
        new_t = temp_t
        var temp_r = r - quotient * new_r
        r = new_r
        new_r = temp_r

    if r != BigInt(1):
        raise Error("inverse does not exist")

    if t < BigInt(0):
        t = t + modulus
    return t


struct Point(ImplicitlyCopyable, Movable):
    var x: BigInt
    var y: BigInt
    var infinity: Bool

    fn __init__(out self):
        self.x = BigInt(0)
        self.y = BigInt(0)
        self.infinity = True


struct SigCompact(Copyable, Movable):
    var r: List[Int]
    var s: List[Int]
    var v: Int

    fn __init__(out self):
        self.r = [0] * 32
        self.s = [0] * 32
        self.v = 0


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

    if a.x == b.x:
        if mod_positive(a.y + b.y, FIELD_P).is_zero():
            return point_infinity()
        return point_double(a)

    var numerator = mod_positive(b.y - a.y, FIELD_P)
    var denominator = mod_inv(b.x - a.x, FIELD_P)
    var lam = mod_positive(numerator * denominator, FIELD_P)
    var xr = mod_positive(lam * lam - a.x - b.x, FIELD_P)
    var yr = mod_positive(lam * (a.x - xr) - a.y, FIELD_P)
    return point_from_xy(xr, yr)


fn point_mul(k: BigInt, base: Point) raises -> Point:
    var scalar = mod_positive(k, CURVE_N)
    var result = point_infinity()
    var addend = base

    while scalar > BigInt(0):
        if scalar % BigInt(2) == BigInt(1):
            result = point_add(result, addend)
        addend = point_double(addend)
        scalar = scalar // BigInt(2)

    return result


fn generator_point() -> Point:
    var p = Point()
    p.infinity = False
    p.x = GEN_X
    p.y = GEN_Y
    return p^


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
    var seed = rfc6979_keccak(msg32, seckey32)
    var counter = 0

    while counter < 1024:
        var input_len = len(seed) + 4
        var material = [0] * input_len
        for i in range(len(seed)):
            material[i] = seed[i] & 0xFF
        material[input_len - 4] = (counter >> 24) & 0xFF
        material[input_len - 3] = (counter >> 16) & 0xFF
        material[input_len - 2] = (counter >> 8) & 0xFF
        material[input_len - 1] = counter & 0xFF

        var k_bytes = keccak256_bytes(material, input_len)
        var k = mod_positive(bytes_to_int_be(k_bytes), CURVE_N)
        counter += 1

        if k.is_zero():
            continue

        var R = point_mul(k, generator_point())
        if R.infinity:
            continue

        var r = mod_positive(R.x, CURVE_N)
        if r.is_zero():
            continue

        var kinv = mod_inv(k, CURVE_N)
        var s = mod_positive(kinv * mod_positive(e + (r * priv), CURVE_N), CURVE_N)
        if s.is_zero():
            continue

        if s > HALF_CURVE_N:
            s = CURVE_N - s

        var recid = 0
        if R.y % BigInt(2) == BigInt(1):
            recid = recid | 1
        if R.x >= CURVE_N:
            recid = recid | 2

        var sig = SigCompact()
        sig.r = int_to_bytes32_be(r)
        sig.s = int_to_bytes32_be(s)
        sig.v = 27 + recid
        return sig.copy()

    raise Error("failed to generate a valid nonce")
