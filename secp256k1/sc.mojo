"""secp256k1 scalar arithmetic modulo n using DeciMojo BigInt."""

from decimojo import BigInt
from decimojo.bigint.bigint import BigUInt


fn make_bigint(var words: List[UInt32]) -> BigInt:
    var magnitude = BigUInt()
    magnitude.words = words^
    var out = BigInt()
    out.magnitude = magnitude
    out.sign = False
    return out


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


fn _mod_positive(value: BigInt, modulus: BigInt) raises -> BigInt:
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
            res = _mod_positive(res * b, modulus)
        b = _mod_positive(b * b, modulus)
        e = e // BigInt(2)
    return res


struct Sc(Movable):
    var value: BigInt

    fn __init__(out self):
        self.value = BigInt()


@always_inline
fn _sc_from_int(value: BigInt) raises -> Sc:
    var r = Sc()
    r.value = _mod_positive(value, CURVE_N)
    return r^


@always_inline
fn _sc_to_int(x: Sc) -> BigInt:
    return x.value


fn sc_zero() raises -> Sc:
    return _sc_from_int(BigInt(0))


fn sc_from_bytes32(inp: List[Int]) raises -> Sc:
    if len(inp) != 32:
        raise Error("sc_from_bytes32 expects 32 bytes")
    var acc = BigInt(0)
    for b in inp:
        acc = acc * BigInt(256) + BigInt(b & 0xFF)
    return _sc_from_int(acc)


fn sc_to_bytes32(x: Sc) raises -> List[Int]:
    var out = [0] * 32
    var v = _mod_positive(x.value, CURVE_N)
    for idx in range(31, -1, -1):
        var byte = v % BigInt(256)
        out[idx] = Int(byte)
        v = v // BigInt(256)
    return out.copy()


fn sc_add(a: Sc, b: Sc) raises -> Sc:
    return _sc_from_int(a.value + b.value)


fn sc_mul(a: Sc, b: Sc) raises -> Sc:
    return _sc_from_int(a.value * b.value)


fn sc_mul_u64(a: Sc, c: UInt64) raises -> Sc:
    var factor = BigInt.from_uint(UInt(c))
    return _sc_from_int(a.value * factor)


fn sc_neg(a: Sc) raises -> Sc:
    if a.value.is_zero():
        return sc_zero()
    return _sc_from_int(CURVE_N - a.value)


fn sc_sub(a: Sc, b: Sc) raises -> Sc:
    return _sc_from_int(a.value - b.value)


fn sc_inv(a: Sc) raises -> Sc:
    var val = _mod_positive(a.value, CURVE_N)
    if val.is_zero():
        raise Error("inverse does not exist for zero scalar")
    
    var exp = CURVE_N - BigInt(2)
    var inv = mod_pow(val, exp, CURVE_N)
    return _sc_from_int(inv)
