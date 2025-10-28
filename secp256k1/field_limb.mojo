# secp256k1/field_limb.mojo
# Pure-limb secp256k1 prime field: p = 2^256 - 2^32 - 977
# Element is 4x64 LE limbs. All ops keep canonical form (0 <= x < p).

from collections.inline_array import InlineArray

struct Fe(Movable):
    var v: InlineArray[UInt64, 4]  # little-endian limbs v[0] + 2^64 v[1] + ...

    fn __init__(out self):
        self.v = InlineArray[UInt64,4](0,0,0,0)

# Factory as a free function (Mojo doesn't allow decorated/static methods in struct body)
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
alias P0 = UInt64(0xFFFFFFFEFFFFFC2F)
alias P1 = UInt64(0xFFFFFFFFFFFFFFFF)
alias P2 = UInt64(0xFFFFFFFFFFFFFFFF)
alias P3 = UInt64(0xFFFFFFFFFFFFFFFF)
@always_inline
fn fe_zero() -> Fe:
    return fe_from_limbs(InlineArray[UInt64,4](0,0,0,0))

@always_inline
fn fe_one() -> Fe:
    return fe_from_limbs(InlineArray[UInt64,4](1,0,0,0))

@always_inline
fn fe_from_bytes32(b: List[Int]) -> Fe:
    var x = InlineArray[UInt64,4](0,0,0,0)
    # bytes are big-endian; fill limbs LE
    var k = 0
    while k < 4:
        var limb: UInt64 = 0
        var j = 0
        while j < 8:
            var idx = ((3 - k) * 8) + j
            var byte = UInt64(b[idx] & 0xFF)
            limb = (limb << UInt64(8)) | byte
            j += 1
        x[k] = limb
        k += 1
    var a = fe_from_limbs(x)
    # If input >= p, subtract p once to canonicalize
    if fe_ge(a, fe_p()):
        a = fe_sub(a, fe_p())
    return a^

@always_inline
fn fe_to_bytes32(a: Fe) -> List[Int]:
    var out = [0] * 32
    var k = 0
    while k < 4:
        var limb = a.v[k]
        var j = 0
        while j < 8:
            var byte = Int(limb & UInt64(0xFF))
            out[31 - (k*8 + j)] = byte
            limb = limb >> UInt64(8)
            j += 1
        k += 1
    return out.copy()

@always_inline
fn fe_p() -> Fe:
    return fe_from_limbs(InlineArray[UInt64,4](P0, P1, P2, P3))

# --- limb utils ---

@always_inline
fn add_carry(a: UInt64, b: UInt64, c: UInt64) -> Tuple[UInt64, UInt64]:
    # returns (sum, carry)
    var s = a + b
    var carry1 = UInt64(s < a)
    s = s + c
    var carry2 = UInt64(s < c)
    return (s, carry1 + carry2)

@always_inline
fn sub_borrow(a: UInt64, b: UInt64, borrow: UInt64) -> Tuple[UInt64, UInt64]:
    # computes a - b - borrow, returns (diff, borrow_out)
    var t = a - b
    var borrow1 = UInt64(a < b)
    var u = t - borrow
    var borrow2 = UInt64(t < borrow)
    return (u, borrow1 + borrow2)

@always_inline
fn mul64_128(a: UInt64, b: UInt64) -> Tuple[UInt64, UInt64]:
    # 64x64->128 via 32-bit halves, portable
    var a0 = a & UInt64(0xFFFFFFFF)
    var a1 = a >> UInt64(32)
    var b0 = b & UInt64(0xFFFFFFFF)
    var b1 = b >> UInt64(32)

    var p00 = a0 * b0
    var p01 = a0 * b1
    var p10 = a1 * b0
    var p11 = a1 * b1

    var mid = (p00 >> UInt64(32)) + (p01 & UInt64(0xFFFFFFFF)) + (p10 & UInt64(0xFFFFFFFF))
    var lo = (p00 & UInt64(0xFFFFFFFF)) | (mid << UInt64(32))
    var hi = (p11) + (p01 >> UInt64(32)) + (p10 >> UInt64(32)) + (mid >> UInt64(32))
    return (lo, hi)

@always_inline
fn fe_ge(a: Fe, b: Fe) -> Bool:
    # compare a >= b (both canonical)
    var i = 3
    while i >= 0:
        if a.v[i] > b.v[i]:
            return True
        if a.v[i] < b.v[i]:
            return False
        i -= 1
    return True  # equal

# --- canonical add/sub ---

@always_inline
fn fe_add(a: Fe, b: Fe) -> Fe:
    var r = InlineArray[UInt64,4](0,0,0,0)
    var c = UInt64(0)
    var i = 0
    while i < 4:
        var s: UInt64
        (s, c) = add_carry(a.v[i], b.v[i], c)
        r[i] = s
        i += 1
    var out = fe_from_limbs(r)
    # conditional subtract p
    var borrow = UInt64(0)
    var d0: UInt64; var d1: UInt64; var d2: UInt64; var d3: UInt64
    (d0, borrow) = sub_borrow(out.v[0], P0, borrow)
    (d1, borrow) = sub_borrow(out.v[1], P1, borrow)
    (d2, borrow) = sub_borrow(out.v[2], P2, borrow)
    (d3, borrow) = sub_borrow(out.v[3], P3, borrow)
    if borrow == UInt64(0):
        return fe_from_limbs(InlineArray[UInt64,4](d0,d1,d2,d3))
    return out^

@always_inline
fn fe_sub(a: Fe, b: Fe) -> Fe:
    var r = InlineArray[UInt64,4](0,0,0,0)
    var borrow = UInt64(0)
    var d: UInt64
    (d, borrow) = sub_borrow(a.v[0], b.v[0], borrow); r[0] = d
    (d, borrow) = sub_borrow(a.v[1], b.v[1], borrow); r[1] = d
    (d, borrow) = sub_borrow(a.v[2], b.v[2], borrow); r[2] = d
    (d, borrow) = sub_borrow(a.v[3], b.v[3], borrow); r[3] = d
    if borrow != UInt64(0):
        # add p back
        var c = UInt64(0)
        (r[0], c) = add_carry(r[0], P0, c)
        (r[1], c) = add_carry(r[1], P1, c)
        (r[2], c) = add_carry(r[2], P2, c)
        (r[3], _) = add_carry(r[3], P3, c)
    return fe_from_limbs(r)

@always_inline
fn fe_neg(a: Fe) -> Fe:
    if a.v[0]==UInt64(0) and a.v[1]==UInt64(0) and a.v[2]==UInt64(0) and a.v[3]==UInt64(0):
        return fe_clone(a)
    return fe_sub(fe_p(), a)

# --- multiply and reduce mod p ---
# Schoolbook 4x4=8 limbs then pseudo-Mersenne fold for p = 2^256 - 2^32 - 977:
# N = L + (H<<32) + 977*H, where L=t0..t3, H=t4..t7 (256 bits each)
fn fe_mul(a: Fe, b: Fe) -> Fe:
    # 1) Schoolbook 4x4 => 8 limbs in t
    var t = InlineArray[UInt64,8](0,0,0,0,0,0,0,0)
    var i = 0
    while i < 4:
        var carry = UInt64(0)
        var j = 0
        while j < 4:
            var lo: UInt64; var hi: UInt64
            (lo, hi) = mul64_128(a.v[i], b.v[j])
            var s: UInt64; var c: UInt64
            (s, c) = add_carry(t[i+j], lo, UInt64(0))
            (s, c) = add_carry(s, carry, c)
            t[i+j] = s
            (s, carry) = add_carry(t[i+j+1], hi, c)
            t[i+j+1] = s
            j += 1
        var k = i + 4
        while carry != UInt64(0):
            var s2: UInt64; var c2: UInt64
            (s2, c2) = add_carry(t[k], UInt64(0), carry)
            t[k] = s2
            carry = c2
            k += 1
        i += 1

    # Split: L=t0..t3, H=t4..t7
    var r = InlineArray[UInt64,5](t[0], t[1], t[2], t[3], 0)  # r4 is overflow sink
    var h0 = t[4]; var h1 = t[5]; var h2 = t[6]; var h3 = t[7]

    # 2) Add (H << 32) into r0..r3; stuff beyond 256 bits goes into r4
    var sh0 = (h0 << UInt64(32))
    var sh1 = (h1 << UInt64(32)) | (h0 >> UInt64(32))
    var sh2 = (h2 << UInt64(32)) | (h1 >> UInt64(32))
    var sh3 = (h3 << UInt64(32)) | (h2 >> UInt64(32))
    var c0 = UInt64(0)
    (r[0], c0) = add_carry(r[0], sh0, c0)
    (r[1], c0) = add_carry(r[1], sh1, c0)
    (r[2], c0) = add_carry(r[2], sh2, c0)
    (r[3], c0) = add_carry(r[3], sh3, c0)
    # true overflow from the shift is (h3 >> 32) + c0
    var overflow = (h3 >> UInt64(32)) + c0
    r[4] = overflow

    # 3) Add 977*H into r with full carry to r4
    var K = UInt64(0x3D1)
    var lo_: UInt64; var hi_: UInt64

    # i=0 -> add to r0,r1 and propagate to r2..r4
    (lo_, hi_) = mul64_128(h0, K)
    c0 = UInt64(0)
    (r[0], c0) = add_carry(r[0], lo_, c0)
    (r[1], c0) = add_carry(r[1], hi_, c0)
    (r[2], c0) = add_carry(r[2], UInt64(0), c0)
    (r[3], c0) = add_carry(r[3], UInt64(0), c0)
    (r[4], c0) = add_carry(r[4], UInt64(0), c0)

    # i=1 -> add to r1,r2 ...
    (lo_, hi_) = mul64_128(h1, K)
    c0 = UInt64(0)
    (r[1], c0) = add_carry(r[1], lo_, c0)
    (r[2], c0) = add_carry(r[2], hi_, c0)
    (r[3], c0) = add_carry(r[3], UInt64(0), c0)
    (r[4], c0) = add_carry(r[4], UInt64(0), c0)

    # i=2 -> add to r2,r3 ...
    (lo_, hi_) = mul64_128(h2, K)
    c0 = UInt64(0)
    (r[2], c0) = add_carry(r[2], lo_, c0)
    (r[3], c0) = add_carry(r[3], hi_, c0)
    (r[4], c0) = add_carry(r[4], UInt64(0), c0)

    # i=3 -> add to r3, carry to r4
    (lo_, hi_) = mul64_128(h3, K)
    c0 = UInt64(0)
    (r[3], c0) = add_carry(r[3], lo_, c0)
    (r[4], c0) = add_carry(r[4], hi_, c0)

    # 4) Fold r4 repeatedly: r += (r4<<32) + 977*r4; update r4; stop when zero
    while r[4] != UInt64(0):
        var ov = r[4]
        r[4] = UInt64(0)

        # add (ov << 32)  ==  low: (ov << 32) into r0,  high: (ov >> 32) into r1
        var cx = UInt64(0)
        (r[0], cx) = add_carry(r[0], (ov << UInt64(32)), cx)
        (r[1], cx) = add_carry(r[1], (ov >> UInt64(32)), cx)       
        (r[2], cx) = add_carry(r[2], UInt64(0), cx)
        (r[3], cx) = add_carry(r[3], UInt64(0), cx)
        (r[4], cx) = add_carry(r[4], UInt64(0), cx)  # any spill goes back to r4

        # add 977*ov
        var lox: UInt64; var hix: UInt64
        var cy = UInt64(0)
        (lox, hix) = mul64_128(ov, K)
        (r[0], cy) = add_carry(r[0], lox, cy)
        (r[1], cy) = add_carry(r[1], hix, cy)
        (r[2], cy) = add_carry(r[2], UInt64(0), cy)
        (r[3], cy) = add_carry(r[3], UInt64(0), cy)
        (r[4], cy) = add_carry(r[4], UInt64(0), cy)

    # 5) Canonicalize using borrow-driven loop: keep subtracting p while no borrow
    var out = fe_from_limbs(InlineArray[UInt64,4](r[0], r[1], r[2], r[3]))
    while True:
        var b = UInt64(0)
        var q0: UInt64; var q1: UInt64; var q2: UInt64; var q3: UInt64
        (q0, b) = sub_borrow(out.v[0], P0, b)
        (q1, b) = sub_borrow(out.v[1], P1, b)
        (q2, b) = sub_borrow(out.v[2], P2, b)
        (q3, b) = sub_borrow(out.v[3], P3, b)
        if b == UInt64(0):
            out = fe_from_limbs(InlineArray[UInt64,4](q0, q1, q2, q3))
            continue
        break
    return out^
@always_inline
fn fe_sqr(a: Fe) -> Fe:
    return fe_mul(a, a)

# --- exponentiation by square-and-multiply for inversion (a^(p-2)) ---
# No BigInt or division needed, just field ops. Slower than EGCD, but simple & safe.
fn fe_pow(a: Fe, exp_be: InlineArray[UInt64,4]) -> Fe:
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

fn fe_inv(a: Fe) -> Fe:
    # exp = p-2 = FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2D
    var e = InlineArray[UInt64,4](
        UInt64(0xFFFFFC2D),
        UInt64(0xFFFFFFFE),
        UInt64(0xFFFFFFFFFFFFFFFF),
        UInt64(0xFFFFFFFFFFFFFFFF)
    )
    return fe_pow(a, e)

# --- normalization hook (no-op; always canonical here) ---
@always_inline
fn fe_normalize_strong(a: Fe) -> Fe:
    return fe_clone(a)
