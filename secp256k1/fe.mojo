"""secp256k1 field arithmetic backed by DeciMojo BigInt."""

from decimojo import BigInt
from decimojo.bigint.bigint import BigUInt


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


struct Fe(Movable):
    var value: BigInt

    fn __init__(out self):
        self.value = BigInt()


@always_inline
fn _fe_from_int(value: BigInt) raises -> Fe:
    var r = Fe()
    r.value = _mod_positive(value, FIELD_P)
    return r^


@always_inline
fn _fe_to_int(a: Fe) -> BigInt:
    return a.value


fn fe_zero() raises -> Fe:
    return _fe_from_int(BigInt(0))


fn fe_one() raises -> Fe:
    return _fe_from_int(BigInt(1))


fn fe_copy(a: Fe) -> Fe:
    var r = Fe()
    r.value = a.value
    return r^


fn fe_add(a: Fe, b: Fe) raises -> Fe:
    return _fe_from_int(a.value + b.value)


fn fe_sub(a: Fe, b: Fe) raises -> Fe:
    return _fe_from_int(a.value - b.value)


fn fe_neg(a: Fe) raises -> Fe:
    if a.value.is_zero():
        return fe_zero()
    return _fe_from_int(FIELD_P - a.value)


fn fe_mul(a: Fe, b: Fe) raises -> Fe:
    return _fe_from_int(a.value * b.value)


fn fe_sqr(a: Fe) raises -> Fe:
    return fe_mul(a, a)


fn fe_inv(a: Fe) raises -> Fe:
    var val = _mod_positive(a.value, FIELD_P)
    if val.is_zero():
        raise Error("inverse does not exist for zero field element")
    
    var exp = FIELD_P - BigInt(2)
    var inv = mod_pow(val, exp, FIELD_P)
    return _fe_from_int(inv)


fn fe_normalize_strong(mut a: Fe) raises:
    a.value = _mod_positive(a.value, FIELD_P)
