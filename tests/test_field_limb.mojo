from secp256k1.field_limb import fe_sub, fe_zero, fe_one, fe_sqr, fe_to_bytes32, fe_from_bytes32, fe_mul, Fe, add_carry, mul64_128

fn probe_pm1_square_prereduce() raises:
    var m1 = fe_sub(fe_zero(), fe_one())
    var a = m1
    var b = m1

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

    var l0=t[0]; var l1=t[1]; var l2=t[2]; var l3=t[3]
    var h0=t[4]; var h1=t[5]; var h2=t[6]; var h3=t[7]
    var l4: UInt64 = 0

    var c: UInt64 = 0
    var lo: UInt64; var hi: UInt64
    (lo, hi) = mul64_128(h0, 977); (l0, c) = add_carry(l0, lo, 0);   (l1, c) = add_carry(l1, hi, c)
    (lo, hi) = mul64_128(h1, 977); (l1, c) = add_carry(l1, lo, c);   (l2, c) = add_carry(l2, hi, c)
    (lo, hi) = mul64_128(h2, 977); (l2, c) = add_carry(l2, lo, c);   (l3, c) = add_carry(l3, hi, c)
    (lo, hi) = mul64_128(h3, 977); (l3, c) = add_carry(l3, lo, c);   (l4, c) = add_carry(l4, hi, c)
    
    var carry_after_977 = c
    c = 0
    (l0, c) = add_carry(l0, (h0 << 32), 0)
    (l1, c) = add_carry(l1, (h0 >> 32), c)
    (l1, c) = add_carry(l1, (h1 << 32), c)
    (l2, c) = add_carry(l2, (h1 >> 32), c)
    (l2, c) = add_carry(l2, (h2 << 32), c)
    (l3, c) = add_carry(l3, (h2 >> 32), c)
    (l3, c) = add_carry(l3, (h3 << 32), c)
    (l4, c) = add_carry(l4, (h3 >> 32), c)
    var extra_count: UInt64 = carry_after_977 + c

    print("pm1^2 pre-reduce l0..l4:", l0, l1, l2, l3, l4, " extra=", extra_count)

    while l4 != 0 or extra_count != 0:
        var top: UInt64
        if l4 != 0:
            top = l4
            l4 = 0
        else:
            top = UInt64(1)
            extra_count -= UInt64(1)
        var cv: UInt64 = 0
        var lo2: UInt64; var hi2: UInt64
        (lo2, hi2) = mul64_128(top, 977)
        (l0, cv) = add_carry(l0, lo2, 0)
        (l1, cv) = add_carry(l1, hi2, cv)
        (l0, cv) = add_carry(l0, (top << 32), cv)
        (l1, cv) = add_carry(l1, (top >> 32), cv)
        (l2, cv) = add_carry(l2, 0, cv)
        (l3, cv) = add_carry(l3, 0, cv)
        (l4, _)  = add_carry(l4, 0, cv)

    print("pm1^2 post-fold l0..l4:", l0, l1, l2, l3, l4)

fn main() raises:
    probe_pm1_square_prereduce()

    # (-1) == p-1
    var m1 = fe_sub(fe_zero(), fe_one())

    # (-1)^2 == 1
    var sq = fe_sqr(m1)
    var one = fe_one()
    if sq.v[0]!=one.v[0] or sq.v[1]!=one.v[1] or sq.v[2]!=one.v[2] or sq.v[3]!=one.v[3]:
        raise Error("(-1)^2 != 1")

    # Round-trip bytes for (-1)
    var b = fe_to_bytes32(m1)
    var rt = fe_from_bytes32(b)
    assert rt.v[0]==m1.v[0] and rt.v[1]==m1.v[1] and rt.v[2]==m1.v[2] and rt.v[3]==m1.v[3], "from/to bytes mismatch"