# secp256k1/field_limb.mojo
# Pure-limb secp256k1 prime field: p = 2^256 - 2^32 - 977
# Element is 4x64 LE limbs. All ops keep canonical form (0 <= x < p).

from collections.inline_array import InlineArray

@always_inline
fn fe_debug_enabled() -> Bool:
    return True

@always_inline
fn fe_mul_trace_enabled() -> Bool:
    return False

alias MASK_U64 = UInt128(0xFFFFFFFFFFFFFFFF)

fn dbg_array_u64[size: Int](label: String, arr: InlineArray[UInt64, size]):
    if fe_mul_trace_enabled():
        print(label, "= [", end="")
        var i = 0
        while i < size:
            print(arr[i], end="")
            if i < size - 1:
                print(", ", end="")
            i += 1
        print("]")

@always_inline
fn dbg_fe(label: String, a: Fe):
    if fe_debug_enabled():
        print(label, a.v[0], a.v[1], a.v[2], a.v[3])

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
    # returns (sum, carry)
    var sum128 = UInt128(a) + UInt128(b) + UInt128(c)
    return (UInt64(sum128 & MASK_U64), UInt64(sum128 >> 64))

@always_inline
fn sub_borrow(a: UInt64, b: UInt64, borrow: UInt64) -> Tuple[UInt64, UInt64]:
    # computes a - b - borrow, returns (diff, borrow_out ∈ {0,1})
    var t = a - b
    var b1 = UInt64(t > a)
    var u = t - borrow
    var b2 = UInt64(u > t)
    return (u, b1 + b2)

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
    var p_or_c = UInt64(fe_ge(out, fe_p())) or UInt64(c != 0)
    var mask = UInt64(0) - p_or_c
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
    if fe_mul_trace_enabled():
        print("--- fe_mul start ---")
        dbg_array_u64[4]("a.v", a.v)
        dbg_array_u64[4]("b.v", b.v)

    # Schoolbook multiplication: 4x4 -> 8 limbs (512-bit product)
    var t = InlineArray[UInt64,8](0,0,0,0,0,0,0,0)
    @parameter
    for i in range(4):
        var carry: UInt128 = 0
        @parameter
        for j in range(4):
            # Multiply two 64-bit limbs to get a 128-bit product
            var prod = UInt128(a.v[i]) * UInt128(b.v[j])
            # Add to the accumulator, including the carry from the previous step
            var total = UInt128(t[i+j]) + (prod & MASK_U64) + carry
            t[i+j] = UInt64(total & MASK_U64)
            # The new carry is the high part of the product plus the carry from the addition
            carry = (prod >> 64) + (total >> 64)
        t[i+4] += UInt64(carry)

    if fe_mul_trace_enabled():
        dbg_array_u64[8]("t (after schoolbook)", t)

    # Modular reduction: 2^256 ≡ 2^32 + 977 (mod p)
    # result = t_low + t_high * (2^32 + 977)
    # Use UInt128 accumulators for clarity.
    var r = InlineArray[UInt128, 5](
        UInt128(t[0]), UInt128(t[1]), UInt128(t[2]), UInt128(t[3]), 0
    )

    # Fold high half (t[4..7]) into low half (r)
    @parameter
    for i in range(4):
        var h = UInt128(t[i + 4])
        # h * 977
        r[i] += h * 977
        # h << 32
        r[i] += h << 32
        r[i + 1] += h >> 32

    # Propagate carries through r.
    var reduction_carry: UInt128 = 0
    @parameter
    for i in range(5):
        var s = r[i] + reduction_carry
        r[i] = s & MASK_U64
        reduction_carry = s >> 64

    # The top limb is now in `reduction_carry`. One final fold.
    if reduction_carry > 0:
        r[0] += reduction_carry * 977
        r[0] += reduction_carry << 32
        r[1] += reduction_carry >> 32
        # Propagate one last time
        var final_carry: UInt128 = 0
        @parameter
        for i in range(4):
            var s = r[i] + final_carry
            r[i] = s & MASK_U64
            final_carry = s >> 64
        # A carry here is astronomically unlikely

    var res_limbs = InlineArray[UInt64,4](
        UInt64(r[0]), UInt64(r[1]), UInt64(r[2]), UInt64(r[3])
    )
    var out = fe_from_limbs(res_limbs)
    out = reduce_once(out)
    out = reduce_once(out)

    if fe_mul_trace_enabled():
        dbg_array_u64[4]("final out.v", out.v)
        print("--- fe_mul end ---")
    return out^

@always_inline
fn fe_sqr(a: Fe) raises -> Fe:
    return fe_mul(a, a)

# --- exponentiation by square-and-multiply for inversion (a^(p-2)) ---
fn fe_pow(a: Fe, exp_be: InlineArray[UInt64,4]) raises -> Fe:
    var base = fe_clone(a)
    var acc = fe_one()
    var limb = 3
    while limb >= 0:
        var word = exp_be[limb]
        var bit = 0
        while bit < 64:
            var acc_sq = fe_sqr(acc)
            acc = acc_sq^
            if (word & (UInt64(1) << UInt64(63 - bit))) != UInt64(0):
                var acc_mul = fe_mul(acc, base)
                acc = acc_mul^
            bit += 1
        limb -= 1
    return acc^

fn fe_inv(a: Fe) raises -> Fe:
    # exp = p-2 = FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2D
    var e = InlineArray[UInt64,4](
        0xFFFFFFFEFFFFFC2D,  # Note: this is P0 - 2
        0xFFFFFFFFFFFFFFFF,
        0xFFFFFFFFFFFFFFFF,
        0xFFFFFFFFFFFFFFFF
    )
    return fe_pow(a, e)

# --- normalization hook (no-op; always canonical here) ---
@always_inline
fn fe_normalize_strong(a: Fe) -> Fe:
    return fe_clone(a)
