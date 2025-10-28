# --- Add this helper function somewhere accessible, e.g., at the top of the file ---
fn dbg_array_u64[size: Int](label: String, arr: InlineArray[UInt64, size]):
    """Prints a UInt64 InlineArray as a Python-style list."""
    print(label, "= [", end="")
    var i = 0
    while i < size:
        print(arr[i], end="")
        if i < size - 1:
            print(", ", end="")
        i += 1
    print("]")

# --- Replace the original fe_mul with this instrumented version ---
fn fe_mul(a: Fe, b: Fe) -> Fe:
    # --- DBG: Print inputs ---
    print("--- fe_mul start ---")
    dbg_array_u64["a.v", 4](a.v)
    dbg_array_u64["b.v", 4](b.v)

    # 1) Schoolbook 4x4 => 8 limbs in t
    var t = InlineArray[UInt64,9](0,0,0,0,0,0,0,0,0)
    var i = 0
    while i < 4:
        var carry = UInt64(0)
        var j = 0
        while j < 4:
            var lo: UInt64; var hi: UInt64
            (lo, hi) = mul64_128(a.v[i], b.v[j])
            var s: UInt64; var c1: UInt64; var c2: UInt64
            (s, c1) = add_carry(t[i+j], lo, UInt64(0))
            (s, c2) = add_carry(s, carry, UInt64(0))
            t[i+j] = s
            var c = c1 + c2
            (s, carry) = add_carry(t[i+j+1], hi, c)
            t[i+j+1] = s
            j += 1
        var k = i + 5
        while carry != UInt64(0):
            var s2: UInt64; var c2: UInt64
            (s2, c2) = add_carry(t[k], UInt64(0), carry)
            t[k] = s2
            carry = c2
            k += 1
        i += 1
    
    # --- DBG: Print result of schoolbook multiplication ---
    dbg_array_u64["t (after schoolbook)", 9](t)

    var r = InlineArray[UInt64,6](t[0], t[1], t[2], t[3], 0, 0)
    var h0 = t[4]; var h1 = t[5]; var h2 = t[6]; var h3 = t[7]

    # 2) Add (H << 32)
    var sh0 = (h0 << UInt64(32)); var sh1 = (h1 << UInt64(32)) | (h0 >> UInt64(32)); var sh2 = (h2 << UInt64(32)) | (h1 >> UInt64(32)); var sh3 = (h3 << UInt64(32)) | (h2 >> UInt64(32))
    var c0 = UInt64(0)
    (r[0], c0) = add_carry(r[0], sh0, c0); (r[1], c0) = add_carry(r[1], sh1, c0); (r[2], c0) = add_carry(r[2], sh2, c0); (r[3], c0) = add_carry(r[3], sh3, c0)
    var overflow = (h3 >> UInt64(32)) + c0
    var spill: UInt64
    (r[4], spill) = add_carry(r[4], overflow, UInt64(0))
    if spill != UInt64(0): (r[5], _) = add_carry(r[5], spill, UInt64(0))

    # 3) Add 977*H
    var K = UInt64(0x3D1)
    var lo_: UInt64; var hi_: UInt64
    (lo_, hi_) = mul64_128(h0, K); c0 = UInt64(0); (r[0], c0) = add_carry(r[0], lo_, c0); (r[1], c0) = add_carry(r[1], hi_, c0)
    var pos = 2; while pos <= 5: (r[pos], c0) = add_carry(r[pos], UInt64(0), c0); pos += 1
    (lo_, hi_) = mul64_128(h1, K); c0 = UInt64(0); (r[1], c0) = add_carry(r[1], lo_, c0); (r[2], c0) = add_carry(r[2], hi_, c0)
    pos = 3; while pos <= 5: (r[pos], c0) = add_carry(r[pos], UInt64(0), c0); pos += 1
    (lo_, hi_) = mul64_128(h2, K); c0 = UInt64(0); (r[2], c0) = add_carry(r[2], lo_, c0); (r[3], c0) = add_carry(r[3], hi_, c0)
    pos = 4; while pos <= 5: (r[pos], c0) = add_carry(r[pos], UInt64(0), c0); pos += 1
    (lo_, hi_) = mul64_128(h3, K); c0 = UInt64(0); (r[3], c0) = add_carry(r[3], lo_, c0); (r[4], c0) = add_carry(r[4], hi_, c0); (r[5], _)  = add_carry(r[5], UInt64(0), c0)

    # --- DBG: Print result after main reduction formula ---
    dbg_array_u64["r (after main reduction)", 6](r)

    # 4a) Fold r[5]
    while r[5] != UInt64(0):
        # ... (folding logic unchanged)
        var ov5 = r[5]; r[5] = UInt64(0)
        var cx = UInt64(0); (r[1], cx) = add_carry(r[1], (ov5 << UInt64(32)), cx); (r[2], cx) = add_carry(r[2], (ov5 >> UInt64(32)), cx); (r[3], cx) = add_carry(r[3], UInt64(0), cx); (r[4], cx) = add_carry(r[4], UInt64(0), cx); (r[5], _)  = add_carry(r[5], UInt64(0), cx)
        var lox: UInt64; var hix: UInt64; (lox, hix) = mul64_128(ov5, K)
        var cy = UInt64(0); (r[1], cy) = add_carry(r[1], lox, cy); (r[2], cy) = add_carry(r[2], hix, cy); (r[3], cy) = add_carry(r[3], UInt64(0), cy); (r[4], cy) = add_carry(r[4], UInt64(0), cy); (r[5], _)  = add_carry(r[5], UInt64(0), cy)

    # 4b) Fold r[4]
    while r[4] != UInt64(0):
        # ... (folding logic unchanged)
        var ov = r[4]; r[4] = UInt64(0)
        var cx2 = UInt64(0); (r[0], cx2) = add_carry(r[0], (ov << UInt64(32)), cx2); (r[1], cx2) = add_carry(r[1], (ov >> UInt64(32)), cx2); (r[2], cx2) = add_carry(r[2], UInt64(0), cx2); (r[3], cx2) = add_carry(r[3], UInt64(0), cx2); (r[4], _)   = add_carry(r[4], UInt64(0), cx2)
        var lox2: UInt64; var hix2: UInt64; (lox2, hix2) = mul64_128(ov, K)
        var cy2 = UInt64(0); (r[0], cy2) = add_carry(r[0], lox2, cy2); (r[1], cy2) = add_carry(r[1], hix2, cy2); (r[2], cy2) = add_carry(r[2], UInt64(0), cy2); (r[3], cy2) = add_carry(r[3], UInt64(0), cy2); (r[4], _)   = add_carry(r[4], UInt64(0), cy2)

    # 5) Canonicalize via borrow-driven loop
    var out = fe_from_limbs(InlineArray[UInt64,4](r[0], r[1], r[2], r[3]))
    
    # --- DBG: Print result before final canonicalization subtraction ---
    dbg_array_u64["out.v (before canonicalize loop)", 4](out.v)
    
    while True:
        var b = UInt64(0)
        var q0: UInt64; var q1: UInt64; var q2: UInt64; var q3: UInt64
        (q0, b) = sub_borrow(out.v[0], P0, b); (q1, b) = sub_borrow(out.v[1], P1, b); (q2, b) = sub_borrow(out.v[2], P2, b); (q3, b) = sub_borrow(out.v[3], P3, b)
        if b == UInt64(0):
            out = fe_from_limbs(InlineArray[UInt64,4](q0, q1, q2, q3))
        else:
            break

    # --- DBG: Print final result ---
    dbg_array_u64["final out.v", 4](out.v)
    print("--- fe_mul end ---")
    return out^