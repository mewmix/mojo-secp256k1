from secp256k1.field_limb import Fe, fe_from_limbs, fe_mul, fe_one

fn main() raises:
    var a = fe_from_limbs(InlineArray[UInt64,4](2,0,0,0))
    var b = fe_one()
    var c = fe_mul(a, b)

    print("a.v[0]: ", a.v[0])
    print("c.v[0]: ", c.v[0])
    if c.v[0] != 2:
        raise Error("2*1 != 2")
