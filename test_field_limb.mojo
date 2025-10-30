# tests/test_field_limb.mojo
from secp256k1.field_limb import (
    Fe, fe_zero, fe_one, fe_p, fe_clone,
    fe_add, fe_sub, fe_neg, fe_mul, fe_sqr, fe_inv,
    fe_from_limbs, fe_from_bytes32, fe_to_bytes32
)
from collections.inline_array import InlineArray

fn assert_eq_bytes(a: List[Int], b: List[Int], msg: String) raises:
    if len(a) != len(b): raise Error(msg + " (len mismatch)")
    var i = 0
    while i < len(a):
        if a[i] != b[i]: raise Error(msg + " @ " + String(i))
        i += 1

fn be_hex_bytes(s: String) -> List[Int]:
    var h = s
    if len(h) % 2 == 1: h = "0" + h
    var out = [0] * (len(h) // 2)
    var i = 0
    while i < len(out):
        var hi = ord(h[2*i]); var lo = ord(h[2*i+1])
        fn nib(c: Int) -> Int:
            if 48 <= c <= 57: return c - 48
            if 97 <= c <= 102: return c - 87
            if 65 <= c <= 70: return c - 55
            return 0
        out[i] = ((nib(hi) << 4) | nib(lo)) & 0xFF
        i += 1
    return out.copy()  # <- important

fn expect_zero(a: Fe, label: String) raises:
    var ab = fe_to_bytes32(a)
    var zb = fe_to_bytes32(fe_zero())
    assert_eq_bytes(ab, zb, label + ": not zero")

fn expect_one(a: Fe, label: String) raises:
    var ab = fe_to_bytes32(a)
    var ob = fe_to_bytes32(fe_one())
    assert_eq_bytes(ab, ob, label + ": not one")

 
# --- debug helpers that avoid printing List[Int] directly (not Writable) ---
fn dbg_fe(label: String, a: Fe):
    # Print the raw LE limbs for quick inspection
    print(label, a.v[0], a.v[1], a.v[2], a.v[3])

fn dbg_bytes(label: String, b: List[Int]):
    # Print bytes as decimal values, one per line (simple & Writable)
    print(label)
    var i = 0
    while i < len(b):
        print(b[i])
        i += 1


fn dbg_hex(b: List[Int]) -> String:
    var s = ""
    var i = 0
    while i < len(b):
        var v = b[i]
        var hi = "0123456789abcdef"[Int((v >> 4) & 15)]
        var lo = "0123456789abcdef"[Int(v & 15)]
        s = s + String(hi) + String(lo)
        i += 1
    return s

fn dump_mul(a_hex: String, b_hex: String) raises:
    var a = fe_from_bytes32(be_hex_bytes(a_hex))
    var b = fe_from_bytes32(be_hex_bytes(b_hex))
    var c = fe_mul(a, b)
    print("A=", a_hex)
    print("B=", b_hex)
    print("C=", dbg_hex(fe_to_bytes32(c)))

fn dbg_hex(b: List[Int]) -> String:
    var s = ""
    var i = 0
    while i < len(b):
        var v = b[i]
        var hi = "0123456789abcdef"[Int((v >> 4) & 15)]
        var lo = "0123456789abcdef"[Int(v & 15)]
        s = s + String(hi) + String(lo)
        i += 1
    return s

fn dump_mul(a_hex: String, b_hex: String) raises:
    var a = fe_from_bytes32(be_hex_bytes(a_hex))
    var b = fe_from_bytes32(be_hex_bytes(b_hex))
    var c = fe_mul(a, b)
    print("A=", a_hex)
    print("B=", b_hex)
    print("C=", dbg_hex(fe_to_bytes32(c)))

fn main() raises:
    dump_mul("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2E", "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2E")
    # p in BE
    var p_be = be_hex_bytes("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F")

    # fe_p encode/roundtrip
    var p = fe_p()
    assert_eq_bytes(fe_to_bytes32(fe_clone(p)), p_be, "fe_p to_bytes32 mismatch")
    var p2 = fe_from_bytes32(p_be)
    # Inputs >= p must reduce; p mod p = 0.
    assert_eq_bytes(
        fe_to_bytes32(fe_clone(p2)),
        fe_to_bytes32(fe_zero()),
        "from_bytes32(p) should be zero"
    )

    # a + 0 = a  and  a - 0 = a
    var a = fe_from_limbs(InlineArray[UInt64,4](123, 0, 0, 0))
    var t = fe_add(fe_clone(a), fe_zero())
    assert_eq_bytes(fe_to_bytes32(t), fe_to_bytes32(fe_clone(a)), "a + 0 != a")
    t = fe_sub(fe_clone(a), fe_zero())
    assert_eq_bytes(fe_to_bytes32(t), fe_to_bytes32(fe_clone(a)), "a - 0 != a")

    # 1 + (p-1) == 0   (derive p-1 canonically as 0 - 1)
    var pm1 = fe_sub(fe_zero(), fe_one())
    expect_zero(fe_add(fe_one(), fe_clone(pm1)), "1 + (p-1)")

    # 0 - 1 == p-1
    assert_eq_bytes(fe_to_bytes32(fe_sub(fe_zero(), fe_one())), fe_to_bytes32(fe_clone(pm1)), "0 - 1 != p-1")

    # (-1)^2 == 1
    var neg1 = fe_clone(pm1)
    var sq = fe_sqr(neg1)

    # debug
    dbg_fe("(-1) limbs:", neg1)
    dbg_bytes("(-1) bytes:", fe_to_bytes32(neg1))
    dbg_fe("(-1)^2 limbs:", sq)
    dbg_bytes("(-1)^2 bytes:", fe_to_bytes32(sq))

    expect_one(sq, "(-1)^2")

    # (p-1)*(p-1) == 1
    expect_one(fe_mul(fe_clone(pm1), fe_clone(pm1)), "(p-1)*(p-1)")

    # 2 * (p-1) == p-2
    var two = fe_from_limbs(InlineArray[UInt64,4](2,0,0,0))
    var pm2 = fe_sub(fe_zero(), two)
    assert_eq_bytes(fe_to_bytes32(fe_mul(two, fe_clone(pm1))), fe_to_bytes32(pm2), "2*(p-1) != p-2")

    # small mul: 2*3 == 6
    var two = fe_from_limbs(InlineArray[UInt64,4](2,0,0,0))
    var three = fe_from_limbs(InlineArray[UInt64,4](3,0,0,0))
    var six = fe_from_limbs(InlineArray[UInt64,4](6,0,0,0))
    assert_eq_bytes(fe_to_bytes32(fe_mul(two, three)), fe_to_bytes32(six), "2*3 != 6")

    # inverse: a * a^{-1} == 1 for a != 0
    var five = fe_from_limbs(InlineArray[UInt64,4](5,0,0,0))
    expect_one(fe_mul(fe_clone(five), fe_inv(five)), "5 * inv(5)")

    # Random-ish properties using a tiny deterministic loop
    var i = 1
    while i <= 16:
        var xi = fe_from_limbs(InlineArray[UInt64,4](UInt64(i),0,0,0))
        var yi = fe_from_limbs(InlineArray[UInt64,4](UInt64(33 - i),0,0,0))
        # commutativity add/mul
        assert_eq_bytes(
            fe_to_bytes32(fe_add(fe_clone(xi), fe_clone(yi))),
            fe_to_bytes32(fe_add(fe_clone(yi), fe_clone(xi))),
            "add not commutative at i="+String(i)
        )
        assert_eq_bytes(
            fe_to_bytes32(fe_mul(fe_clone(xi), fe_clone(yi))),
            fe_to_bytes32(fe_mul(fe_clone(yi), fe_clone(xi))),
            "mul not commutative at i="+String(i)
        )
        # distributivity: x*(y+1) == x*y + x
        var lhs = fe_mul(fe_clone(xi), fe_add(fe_clone(yi), fe_one()))
        var rhs = fe_add(fe_mul(fe_clone(xi), fe_clone(yi)), fe_clone(xi))
        assert_eq_bytes(fe_to_bytes32(lhs), fe_to_bytes32(rhs), "distributivity fail i="+String(i))
        i += 1

    print("PASS: field_limb basic algebra checks")