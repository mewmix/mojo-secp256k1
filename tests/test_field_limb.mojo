from secp256k1.field_limb import fe_from_limbs, fe_clone, fe_sub, fe_zero, fe_one, fe_sqr, fe_to_bytes32, fe_from_bytes32, fe_mul, add_carry, mul64_128, fe_p, fe_ge, Fe

fn test_pm1_squared() raises:
    print("Test: (p-1)^2 == 1")
    var pm1 = fe_sub(fe_p(), fe_one())
    var pm1_sq = fe_sqr(pm1)
    var one = fe_one()
    @parameter
    for i in range(4):
        if pm1_sq.v[i] != one.v[i]:
            raise Error("FAIL: (-1)^2 != 1")
    print("... OK")

fn test_fe_sqr_vs_mul() raises:
    print("Test: fe_sqr(a) == fe_mul(a,a)")
    # A value that's tricky to square
    var limbs = InlineArray[UInt64, 4](
        0xFFFFFFFEFFFFFC2E, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
    )
    var a = fe_from_limbs(limbs)
    var sq1 = fe_sqr(a)
    var sq2 = fe_mul(a, a)
    @parameter
    for i in range(4):
        if sq1.v[i] != sq2.v[i]:
            raise Error("FAIL: fe_sqr(a) != fe_mul(a,a)")
    print("... OK")

fn test_from_to_bytes() raises:
    print("Test: from_bytes32 . to_bytes32 == id")
    var m1 = fe_sub(fe_zero(), fe_one())
    var b = fe_to_bytes32(m1)
    var rt = fe_from_bytes32(b)
    @parameter
    for i in range(4):
        if rt.v[i] != m1.v[i]:
            raise Error("FAIL: from/to bytes mismatch for -1")
    print("... OK")

fn main() raises:
    test_pm1_squared()
    test_fe_sqr_vs_mul()
    test_from_to_bytes()
    print("\nAll tests passed.")
