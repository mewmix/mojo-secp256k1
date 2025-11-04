"""secp256k1 scalar arithmetic modulo n using 4×64-bit Montgomery arithmetic."""

from collections.inline_array import InlineArray

alias MASK_U64 = UInt128(0xFFFFFFFFFFFFFFFF)
alias N0 = 0xBFD25E8CD0364141
alias N1 = 0xBAAEDCE6AF48A03B
alias N2 = 0xFFFFFFFFFFFFFFFE
alias N3 = 0xFFFFFFFFFFFFFFFF
alias N_INV = UInt64(0x4B0DFF665588B13F)
alias N_MINUS_2_0 = UInt64(0xBFD25E8CD036413F)
alias N_MINUS_2_1 = UInt64(0xBAAEDCE6AF48A03B)
alias N_MINUS_2_2 = UInt64(0xFFFFFFFFFFFFFFFE)
alias N_MINUS_2_3 = UInt64(0xFFFFFFFFFFFFFFFF)
alias INT64_MAX = UInt64(0x7FFFFFFFFFFFFFFF)

fn sc_modulus_limbs() -> InlineArray[UInt64,4]:
    return InlineArray[UInt64,4](UInt64(N0), UInt64(N1), UInt64(N2), UInt64(N3))

fn rr_limbs() -> InlineArray[UInt64,4]:
    return InlineArray[UInt64,4](
        UInt64(0x896CF21467D7D140),
        UInt64(0x741496C20E7CF878),
        UInt64(0xE697F5E45BCD07C6),
        UInt64(0x9D671CD581C69BC5),
    )

fn r_mod_limbs() -> InlineArray[UInt64,4]:
    return InlineArray[UInt64,4](
        UInt64(0x402DA1732FC9BEBF),
        UInt64(0x4551231950B75FC4),
        UInt64(0x0000000000000001),
        UInt64(0x0000000000000000),
    )

struct Sc(Movable):
    var v: InlineArray[UInt64,4]

    fn __init__(out self):
        self.v = InlineArray[UInt64,4](0,0,0,0)

@always_inline
fn sc_from_limbs(v: InlineArray[UInt64,4]) -> Sc:
    var r = Sc()
    r.v = v
    return r^

@always_inline
fn add_carry(a: UInt64, b: UInt64, c: UInt64) -> Tuple[UInt64, UInt64]:
    var sum128 = UInt128(a) + UInt128(b) + UInt128(c)
    return (UInt64(sum128 & MASK_U64), UInt64(sum128 >> 64))

@always_inline
fn sub_borrow(a: UInt64, b: UInt64, borrow: UInt64) -> Tuple[UInt64, UInt64]:
    var t = a - b
    var b1 = UInt64(t > a)
    var u = t - borrow
    var b2 = UInt64(u > t)
    return (u, b1 + b2)

@always_inline
fn mul64_128(a: UInt64, b: UInt64) -> Tuple[UInt64, UInt64]:
    var prod = UInt128(a) * UInt128(b)
    var lo = UInt64(prod & MASK_U64)
    var hi = UInt64(prod >> 64)
    return (lo, hi)

@always_inline
fn sc_ge_limbs(a: InlineArray[UInt64,4], b: InlineArray[UInt64,4]) -> Bool:
    var i = 3
    while i >= 0:
        if a[i] > b[i]:
            return True
        if a[i] < b[i]:
            return False
        i -= 1
    return True

@always_inline
fn sc_is_zero(a: Sc) -> Bool:
    return a.v[0] == 0 and a.v[1] == 0 and a.v[2] == 0 and a.v[3] == 0

@always_inline
fn sc_select(mask: UInt64, x: InlineArray[UInt64,4], y: InlineArray[UInt64,4]) -> InlineArray[UInt64,4]:
    var r = InlineArray[UInt64,4](0,0,0,0)
    @parameter
    for i in range(4):
        r[i] = (x[i] & mask) | (y[i] & ~mask)
    return r

fn sc_sub_raw(a: InlineArray[UInt64,4], b: InlineArray[UInt64,4]) -> InlineArray[UInt64,4]:
    var diff = InlineArray[UInt64,4](0,0,0,0)
    var borrow: UInt64 = 0
    @parameter
    for i in range(4):
        (diff[i], borrow) = sub_borrow(a[i], b[i], borrow)
    var addback = InlineArray[UInt64,4](0,0,0,0)
    var carry: UInt64 = 0
    var n = sc_modulus_limbs()
    @parameter
    for i in range(4):
        (addback[i], carry) = add_carry(diff[i], n[i], carry)
    var mask = UInt64(0) - UInt64(borrow > 0)
    return sc_select(mask, addback, diff)

fn sc_add_raw(a: InlineArray[UInt64,4], b: InlineArray[UInt64,4]) -> InlineArray[UInt64,4]:
    var sum = InlineArray[UInt64,4](0,0,0,0)
    var carry: UInt64 = 0
    @parameter
    for i in range(4):
        (sum[i], carry) = add_carry(a[i], b[i], carry)
    var n = sc_modulus_limbs()
    var tmp = InlineArray[UInt64,4](0,0,0,0)
    var borrow: UInt64 = 0
    @parameter
    for i in range(4):
        (tmp[i], borrow) = sub_borrow(sum[i], n[i], borrow)
    var need_sub = UInt64(0)
    if carry != 0 or sc_ge_limbs(sum, n):
        need_sub = UInt64(1)
    var mask = UInt64(0) - need_sub
    return sc_select(mask, tmp, sum)

fn sc_reduce_once(a: InlineArray[UInt64,4]) -> InlineArray[UInt64,4]:
    return sc_sub_raw(a, sc_modulus_limbs())

fn mont_reduce(t_in: InlineArray[UInt64,8]) -> InlineArray[UInt64,4]:
    var t = InlineArray[UInt64,9](
        t_in[0], t_in[1], t_in[2], t_in[3],
        t_in[4], t_in[5], t_in[6], t_in[7],
        UInt64(0),
    )
    var n = sc_modulus_limbs()
    var i = 0
    while i < 4:
        var m = UInt64((UInt128(t[i]) * UInt128(N_INV)) & MASK_U64)
        var carry = UInt128(0)
        var j = 0
        while j < 4:
            var prod = UInt128(m) * UInt128(n[j])
            var acc = UInt128(t[i+j]) + prod + carry
            t[i+j] = UInt64(acc & MASK_U64)
            carry = acc >> 64
            j += 1
        var idx = i + 4
        while carry != UInt128(0):
            var acc = UInt128(t[idx]) + carry
            t[idx] = UInt64(acc & MASK_U64)
            carry = acc >> 64
            idx += 1
        i += 1
    var r = InlineArray[UInt64,4](t[4], t[5], t[6], t[7])
    var extra = t[8]
    if extra != UInt64(0):
        var base = r_mod_limbs()
        var acc = r
        var k = extra
        while k != UInt64(0):
            if (k & UInt64(1)) == UInt64(1):
                acc = sc_add_raw(acc, base)
            k = k >> UInt64(1)
            if k != UInt64(0):
                base = sc_add_raw(base, base)
        r = acc
    if sc_ge_limbs(r, n):
        var borrow: UInt64 = 0
        var reduced = InlineArray[UInt64,4](0,0,0,0)
        @parameter
        for k in range(4):
            (reduced[k], borrow) = sub_borrow(r[k], n[k], borrow)
        return reduced
    return r

fn mont_mul(a: InlineArray[UInt64,4], b: InlineArray[UInt64,4]) -> InlineArray[UInt64,4]:
    var t = InlineArray[UInt64,9](0,0,0,0,0,0,0,0,0)
    var i = 0
    while i < 4:
        var carry = UInt128(0)
        var j = 0
        while j < 4:
            var prod = UInt128(a[i]) * UInt128(b[j])
            var acc = UInt128(t[i+j]) + prod + carry
            t[i+j] = UInt64(acc & MASK_U64)
            carry = acc >> 64
            j += 1
        var idx = i + 4
        while carry != UInt128(0):
            var acc = UInt128(t[idx]) + carry
            t[idx] = UInt64(acc & MASK_U64)
            carry = acc >> 64
            idx += 1
        i += 1
    var product = InlineArray[UInt64,8](t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7])
    return mont_reduce(product)

@always_inline
fn to_mont(a: InlineArray[UInt64,4]) -> InlineArray[UInt64,4]:
    return mont_mul(a, rr_limbs())

@always_inline
fn from_mont(a: InlineArray[UInt64,4]) -> InlineArray[UInt64,4]:
    return mont_mul(a, InlineArray[UInt64,4](1,0,0,0))

fn sc_pow(base: InlineArray[UInt64,4], exp: InlineArray[UInt64,4]) -> InlineArray[UInt64,4]:
    var base_m = to_mont(base)
    var acc = to_mont(InlineArray[UInt64,4](1,0,0,0))
    var limb = 3
    while limb >= 0:
        var word = exp[limb]
        var bit = 0
        while bit < 64:
            acc = mont_mul(acc, acc)
            var shift = UInt64(63 - bit)
            if (word & (UInt64(1) << shift)) != UInt64(0):
                acc = mont_mul(acc, base_m)
            bit += 1
        limb -= 1
    return from_mont(acc)

fn sc_zero() -> Sc:
    return sc_from_limbs(InlineArray[UInt64,4](0,0,0,0))

fn sc_from_bytes32(inp: List[Int]) raises -> Sc:
    if len(inp) != 32:
        raise Error("sc_from_bytes32 expects 32 bytes")
    var limbs = InlineArray[UInt64,4](0,0,0,0)
    @parameter
    for k in range(4):
        var limb: UInt64 = 0
        @parameter
        for j in range(8):
            var idx = 31 - (k * 8 + j)
            limb |= UInt64(inp[idx] & 0xFF) << UInt64(j * 8)
        limbs[k] = limb
    var reduced = sc_reduce_once(limbs)
    return sc_from_limbs(reduced)

fn sc_to_bytes32(x: Sc) -> List[Int]:
    var out = [0] * 32
    @parameter
    for k in range(4):
        var limb = x.v[k]
        @parameter
        for j in range(8):
            out[31 - (k * 8 + j)] = Int((limb >> UInt64(j * 8)) & 0xFF)
    return out.copy()

fn sc_add(a: Sc, b: Sc) -> Sc:
    return sc_from_limbs(sc_add_raw(a.v, b.v))

fn sc_sub(a: Sc, b: Sc) -> Sc:
    return sc_from_limbs(sc_sub_raw(a.v, b.v))

fn sc_neg(a: Sc) -> Sc:
    if sc_is_zero(a):
        return sc_zero()
    var res = InlineArray[UInt64,4](0,0,0,0)
    var borrow: UInt64 = 0
    var n = sc_modulus_limbs()
    @parameter
    for i in range(4):
        (res[i], borrow) = sub_borrow(n[i], a.v[i], borrow)
    return sc_from_limbs(res)

fn sc_mul(a: Sc, b: Sc) -> Sc:
    var a_m = to_mont(a.v)
    var b_m = to_mont(b.v)
    var prod_m = mont_mul(a_m, b_m)
    var limbs = from_mont(prod_m)
    return sc_from_limbs(limbs)

fn sc_mul_u64(a: Sc, c: UInt64) -> Sc:
    var b = InlineArray[UInt64,4](c,0,0,0)
    var a_m = to_mont(a.v)
    var b_m = to_mont(sc_reduce_once(b))
    var prod_m = mont_mul(a_m, b_m)
    var limbs = from_mont(prod_m)
    return sc_from_limbs(limbs)

fn sc_inv(a: Sc) raises -> Sc:
    if sc_is_zero(a):
        raise Error("inverse does not exist for zero scalar")
    var exp = InlineArray[UInt64,4](N_MINUS_2_0, N_MINUS_2_1, N_MINUS_2_2, N_MINUS_2_3)
    var limbs = sc_pow(a.v, exp)
    return sc_from_limbs(limbs)

fn sc_from_u64(value: UInt64) -> Sc:
    var limbs = InlineArray[UInt64,4](value, 0, 0, 0)
    return sc_from_limbs(limbs)

fn _sc_from_int(value: Int) raises -> Sc:
    if value < 0:
        raise Error("_sc_from_int expects a non-negative value")
    var limbs = InlineArray[UInt64,4](UInt64(value), 0, 0, 0)
    return sc_from_limbs(limbs)

fn _sc_to_int(x: Sc) raises -> Int:
    if x.v[1] != UInt64(0) or x.v[2] != UInt64(0) or x.v[3] != UInt64(0):
        raise Error("scalar value does not fit in Int")
    if x.v[0] > INT64_MAX:
        raise Error("scalar value exceeds Int range")
    return Int(x.v[0])

fn sc_modulus_bytes32() -> List[Int]:
    var n = sc_modulus_limbs()
    var out = [0] * 32
    @parameter
    for k in range(4):
        var limb = n[k]
        @parameter
        for j in range(8):
            out[31 - (k * 8 + j)] = Int((limb >> UInt64(j * 8)) & UInt64(0xFF))
    return out.copy()

@always_inline
fn sc_is_odd(a: Sc) -> Bool:
    return (a.v[0] & 1) == 1

fn sc_shr1(out r: Sc, a: Sc):
    r.v[0] = (a.v[0] >> 1) | (a.v[1] << 63)
    r.v[1] = (a.v[1] >> 1) | (a.v[2] << 63)
    r.v[2] = (a.v[2] >> 1) | (a.v[3] << 63)
    r.v[3] = (a.v[3] >> 1)

fn sc_add_u64(a: Sc, c: UInt64) -> Sc:
    var b = InlineArray[UInt64,4](c, 0, 0, 0)
    return sc_from_limbs(sc_add_raw(a.v, b))
