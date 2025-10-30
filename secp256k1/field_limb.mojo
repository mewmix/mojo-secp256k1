# secp256k1/field_limb.mojo
# Pure-limb secp256k1 prime field: p = 2^256 - 2^32 - 977
# Element is 4x64 LE limbs. All ops keep canonical form (0 <= x < p).

from collections.inline_array import InlineArray

alias DEBUG_FE = False

@always_inline
fn dbg_r(label: String, r: InlineArray[UInt64,6]):
    if DEBUG_FE:
        print(label, r[0], r[1], r[2], r[3], r[4], r[5])

struct Fe(Movable):
    var v: InlineArray[UInt64, 4]  # little-endian limbs v[0] + 2^64 v[1] + ...

    fn __init__(out self):
        self.v = InlineArray[UInt64,4](0,0,0,0)

# Factory as a free function
@always_inline
fn fe_from_limbs(v: InlineArray[UInt64,4]) -> Fe:
    var r = Fe()
    r.v = v
    return r^

@always_inline
fn fe_clone(a: Fe) -> Fe:
    var r = Fe()
    r.v = a.v
    return r^

# --- Prime p in 4x64 LE limbs ---
# p = FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
alias P0 = 0xFFFFFFFEFFFFFC2F
alias P1 = 0xFFFFFFFFFFFFFFFF
alias P2 = 0xFFFFFFFFFFFFFFFF
alias P3 = 0xFFFFFFFFFFFFFFFF

@always_inline
fn fe_zero() -> Fe:
    return fe_from_limbs(InlineArray[UInt64,4](0,0,0,0))

@always_inline
fn fe_one() -> Fe:
    return fe_from_limbs(InlineArray[UInt64,4](1,0,0,0))

@always_inline
fn fe_from_bytes32(b: List[Int]) -> Fe:
    var x = InlineArray[UInt64,4](0,0,0,0)
    @parameter
    for k in range(4):
        var limb: UInt64 = 0
        @parameter
        for j in range(8):
            var idx = 31 - (k * 8 + j)
            limb |= UInt64(b[idx] & 0xFF) << UInt64(j*8)
        x[k] = limb
    var a = fe_from_limbs(x)
    return reduce_once(a)

@always_inline
fn fe_to_bytes32(a: Fe) -> List[Int]:
    var out = [0] * 32
    @parameter
    for k in range(4):
        var limb = a.v[k]
        @parameter
        for j in range(8):
            out[31 - (k*8 + j)] = Int((limb >> UInt64(j*8)) & 0xFF)
    return out.copy()

@always_inline
fn fe_p() -> Fe:
    return fe_from_limbs(InlineArray[UInt64,4](UInt64(P0), UInt64(P1), UInt64(P2), UInt64(P3)))

# --- limb utils ---
@always_inline
fn add_carry(a: UInt64, b: UInt64, c: UInt64) -> Tuple[UInt64, UInt64]:
    # returns (sum, carry ∈ {0,1,2})  — adding three 64-bit values
    var s = a + b
    var c1 = UInt64(s < a)           # 0 or 1
    s = s + c
    var c2 = UInt64(s < c)           # 0 or 1
    return (s, c1 + c2)              # 0..2

@always_inline
fn sub_borrow(a: UInt64, b: UInt64, borrow: UInt64) -> Tuple[UInt64, UInt64]:
    # computes a - b - borrow, returns (diff, borrow_out ∈ {0,1,2})
    var t = a - b
    var b1 = UInt64(a < b)           # 0 or 1
    var u = t - borrow
    var b2 = UInt64(t < borrow)      # 0 or 1
    return (u, b1 + b2)              # 0..2

@always_inline
fn mul64_128(a: UInt64, b: UInt64) -> Tuple[UInt64, UInt64]:
    # 64x64->128 via 32-bit halves, portable
    var a0 = a & 0xFFFFFFFF; var a1 = a >> 32
    var b0 = b & 0xFFFFFFFF; var b1 = b >> 32
    var p00 = a0 * b0
    var p01 = a0 * b1
    var p10 = a1 * b0
    var p11 = a1 * b1
    var mid = (p00 >> 32) + (p01 & 0xFFFFFFFF) + (p10 & 0xFFFFFFFF)
    var lo = (p00 & 0xFFFFFFFF) | (mid << 32)
    var hi = p11 + (p01 >> 32) + (p10 >> 32) + (mid >> 32)
    return (lo, hi)

@always_inline
fn fe_ge(a: Fe, b: Fe) -> Bool:
    # compare a >= b (both canonical)
    var i = 3
    while i >= 0:
        if a.v[i] > b.v[i]: return True
        if a.v[i] < b.v[i]: return False
        i -= 1
    return True

# Branchless select
@always_inline
fn fe_select(mask: UInt64, x: Fe, y: Fe) -> Fe:
    var r = InlineArray[UInt64,4](0,0,0,0)
    @parameter
    for i in range(4):
        r[i] = (x.v[i] & mask) | (y.v[i] & ~mask)
    return fe_from_limbs(r)


# --- canonical add/sub ---
@always_inline
fn fe_add(a: Fe, b: Fe) -> Fe:
    var r = InlineArray[UInt64,4](0,0,0,0)
    var c: UInt64 = 0
    @parameter
    for i in range(4):
        (r[i], c) = add_carry(a.v[i], b.v[i], c)
    var out = fe_from_limbs(r)
    # if c>0 or out >= p, subtract p
    var p_limbs = InlineArray[UInt64,4](UInt64(P0), UInt64(P1), UInt64(P2), UInt64(P3))
    var borrow: UInt64 = 0
    var d = InlineArray[UInt64,4](0,0,0,0)
    @parameter
    for i in range(4):
        (d[i], borrow) = sub_borrow(out.v[i], p_limbs[i], borrow)
    # clamp multi-bit carry to boolean for masking
    var p_or_c = UInt64(fe_ge(out, fe_p())) | UInt64(c != 0)
    var mask = UInt64(0) - UInt64(p_or_c != 0)
    return fe_select(mask, fe_from_limbs(d), out)

@always_inline
fn fe_sub(a: Fe, b: Fe) -> Fe:
    var r = InlineArray[UInt64,4](0,0,0,0)
    var borrow: UInt64 = 0
    @parameter
    for i in range(4):
        (r[i], borrow) = sub_borrow(a.v[i], b.v[i], borrow)
    # if borrow, add p
    var p_limbs = InlineArray[UInt64,4](UInt64(P0), UInt64(P1), UInt64(P2), UInt64(P3))
    var c: UInt64 = 0
    var d = InlineArray[UInt64,4](0,0,0,0)
    @parameter
    for i in range(4):
        (d[i], c) = add_carry(r[i], p_limbs[i], c)
    # clamp multi-bit borrow to boolean for masking
    var mask = UInt64(0) - UInt64(borrow > 0)
    return fe_select(mask, fe_from_limbs(d), fe_from_limbs(r))

@always_inline
fn fe_neg(a: Fe) -> Fe:
    return fe_sub(fe_zero(), a)

# --- multiply and reduce mod p ---
@always_inline
fn reduce_once(a: Fe) -> Fe:
    var sub_res = fe_sub(a, fe_p())
    var mask = UInt64(0) - UInt64(fe_ge(a, fe_p()))
    return fe_select(mask, sub_res, a)

fn fe_mul(a: Fe, b: Fe) raises -> Fe:
    var t = InlineArray[UInt64,8](0,0,0,0,0,0,0,0)
    @parameter
    for i in range(4):
        var carry: UInt64 = 0
        @parameter
        for j in range(4):
            var lo, hi = mul64_128(a.v[i], b.v[j])
            var s, c = add_carry(t[i+j], lo, 0)
            (s, c) = add_carry(s, carry, c)
            t[i+j] = s
            var s2, c2 = add_carry(t[i+j+1], hi, c)
            t[i+j+1] = s2
            carry = c2
        var k = i + 4
        while carry != 0:
            (t[k], carry) = add_carry(t[k], 0, carry)
            k += 1

    var l0 = t[0]; var l1 = t[1]; var l2 = t[2]; var l3 = t[3]
    var h0 = t[4]; var h1 = t[5]; var h2 = t[6]; var h3 = t[7]

    # Single-pass fold with C = 2^32 + 977  (since 2^256 ≡ C mod p)
    alias C = UInt64(0x1000003D1)

    # Work buffer with two extra limbs to catch cascaded carries
    var l = InlineArray[UInt64, 6](l0, l1, l2, l3, 0, 0)

    var lo: UInt64; var hi: UInt64
    var c: UInt64

    # Add h0 * C at position 0
    (lo, hi) = mul64_128(h0, C)
    c = 0
    (l[0], c) = add_carry(l[0], lo, 0)
    (l[1], c) = add_carry(l[1], hi, c)
    (l[2], c) = add_carry(l[2], 0,  c)
    (l[3], c) = add_carry(l[3], 0,  c)
    (l[4], c) = add_carry(l[4], 0,  c)
    (l[5], _) = add_carry(l[5], 0,  c)

    # Add h1 * C at position 1
    (lo, hi) = mul64_128(h1, C)
    c = 0
    (l[1], c) = add_carry(l[1], lo, 0)
    (l[2], c) = add_carry(l[2], hi, c)
    (l[3], c) = add_carry(l[3], 0,  c)
    (l[4], c) = add_carry(l[4], 0,  c)
    (l[5], _) = add_carry(l[5], 0,  c)

    # Add h2 * C at position 2
    (lo, hi) = mul64_128(h2, C)
    c = 0
    (l[2], c) = add_carry(l[2], lo, 0)
    (l[3], c) = add_carry(l[3], hi, c)
    (l[4], c) = add_carry(l[4], 0,  c)
    (l[5], _) = add_carry(l[5], 0,  c)

    # Add h3 * C at position 3
    (lo, hi) = mul64_128(h3, C)
    c = 0
    (l[3], c) = add_carry(l[3], lo, 0)
    (l[4], c) = add_carry(l[4], hi, c)
    (l[5], _) = add_carry(l[5], 0,  c)

    # Re-fold any overflow limbs:
    # l[4] corresponds to 2^256 * k  -> add k * C at pos 0
    # l[5] corresponds to 2^320 * k  -> add k * C at pos 1  (since 2^320 ≡ (2^64)*C)
    while l[4] != 0 or l[5] != 0:
        if l[4] != 0:
            var top0 = l[4]; l[4] = 0
            (lo, hi) = mul64_128(top0, C)
            c = 0
            (l[0], c) = add_carry(l[0], lo, 0)
            (l[1], c) = add_carry(l[1], hi, c)
            (l[2], c) = add_carry(l[2], 0,  c)
            (l[3], c) = add_carry(l[3], 0,  c)
            (l[4], c) = add_carry(l[4], 0,  c)
            (l[5], _) = add_carry(l[5], 0,  c)
        if l[5] != 0:
            var top1 = l[5]; l[5] = 0
            (lo, hi) = mul64_128(top1, C)   # add starting at pos 1 (<<64)
            c = 0
            (l[1], c) = add_carry(l[1], lo, 0)
            (l[2], c) = add_carry(l[2], hi, c)
            (l[3], c) = add_carry(l[3], 0,  c)
            (l[4], c) = add_carry(l[4], 0,  c)
            (l[5], _) = add_carry(l[5], 0,  c)

    var out = fe_from_limbs(InlineArray[UInt64,4](l[0], l[1], l[2], l[3]))

    # Canonicalize: at most 2 subtractions are ever needed
    out = reduce_once(out)
    out = reduce_once(out)
    if DEBUG_FE:
        print("out limbs:", out.v[0], out.v[1], out.v[2], out.v[3])
    return out^

@always_inline
fn fe_sqr(a: Fe) raises -> Fe:
    return fe_mul(a, a)

# --- exponentiation by square-and-multiply for inversion (a^(p-2)) ---
# No BigInt or division needed, just field ops. Slower than EGCD, but simple & safe.
fn fe_pow(a: Fe, exp_be: InlineArray[UInt64,4]) raises -> Fe:
    var base = fe_clone(a)
    var acc = fe_one()
    var limb = 3
    while limb >= 0:
        var word = exp_be[limb]
        var bit = 0
        while bit < 64:
            var acc_sq = fe_sqr(acc)
            acc = acc_sq^  # move
            if (word & (UInt64(1) << UInt64(63 - bit))) != UInt64(0):
                var acc_mul = fe_mul(acc, base)
                acc = acc_mul^  # move
            bit += 1
        limb -= 1
    return acc^

fn fe_inv(a: Fe) raises -> Fe:
    # exp = p-2 = FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2D
    var e = InlineArray[UInt64,4](
        0xFFFFFC2D,
        0xFFFFFFFE,
        0xFFFFFFFFFFFFFFFF,
        0xFFFFFFFFFFFFFFFF
    )
    return fe_pow(a, e)

# --- normalization hook (no-op; always canonical here) ---
@always_inline
fn fe_normalize_strong(a: Fe) -> Fe:
    return fe_clone(a)
