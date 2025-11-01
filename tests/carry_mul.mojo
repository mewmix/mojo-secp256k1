from secp256k1.field_limb import Fe, fe_from_limbs, fe_mul, fe_one

fn main() raises:
    var a = fe_from_limbs(InlineArray[UInt64,4](0, 1, 0, 0)) # 2^64
    var b = fe_from_limbs(InlineArray[UInt64,4](0, 1, 0, 0)) # 2^64
    var c = fe_mul(a, b)

    print("a.v[1]: ", a.v[1])
    print("c.v[0]: ", c.v[0])
    print("c.v[1]: ", c.v[1])
    # 2^64 * 2^64 = 2^128. After reduction, this should not be zero.
    if c.v[0] == 0 and c.v[1] == 0:
        raise Error("carry multiplication failed")
