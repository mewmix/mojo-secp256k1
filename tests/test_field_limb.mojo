from secp256k1.field_limb import fe_from_limbs, fe_clone, fe_sub, fe_zero, fe_one, fe_sqr, fe_to_bytes32, fe_from_bytes32, fe_mul, fe_mul_scalar, fe_double, add_carry, mul64_128, fe_p, fe_ge, Fe

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

fn fe_equal(a: Fe, b: Fe) -> Bool:
    return a.v[0] == b.v[0] and a.v[1] == b.v[1] and a.v[2] == b.v[2] and a.v[3] == b.v[3]

fn test_mul_scalar() raises:
    print("Test: fe_mul_scalar")
    var a = fe_from_limbs(InlineArray[UInt64,4](1,2,3,4))

    # Test mul by 0
    var res0 = fe_mul_scalar(a, 0)
    if not fe_equal(res0, fe_zero()):
        raise Error("FAIL: fe_mul_scalar(a, 0) != 0")

    # Test mul by 1
    var res1 = fe_mul_scalar(a, 1)
    if not fe_equal(res1, a):
        raise Error("FAIL: fe_mul_scalar(a, 1) != a")

    # Test mul by 2
    var res2 = fe_mul_scalar(a, 2)
    var dbl = fe_double(a)
    if not fe_equal(res2, dbl):
        raise Error("FAIL: fe_mul_scalar(a, 2) != fe_double(a)")

    # Compare against fe_mul
    var b = fe_from_limbs(InlineArray[UInt64,4](12345, 0, 0, 0))
    var res3 = fe_mul_scalar(a, 12345)
    var res4 = fe_mul(a, b)
    if not fe_equal(res3, res4):
        raise Error("FAIL: fe_mul_scalar(a, k) != fe_mul(a, fe(k))")

    print("... OK")

fn main() raises:
    test_pm1_squared()
    test_fe_sqr_vs_mul()
    test_from_to_bytes()
    test_mul_scalar()
    print("\nAll tests passed.")
