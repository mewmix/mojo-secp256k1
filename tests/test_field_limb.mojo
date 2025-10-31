from secp256k1.field_limb import fe_sub, fe_zero, fe_one, fe_sqr, fe_to_bytes32, fe_from_bytes32, fe_mul, Fe, add_carry, mul64_128, fe_clone

fn main() raises:
    # (-1) == p-1
    var m1 = fe_sub(fe_zero(), fe_one())

    # (-1)^2 == 1
    var sq = fe_sqr(m1)
    var one = fe_one()
    if sq.v[0]!=one.v[0] or sq.v[1]!=one.v[1] or sq.v[2]!=one.v[2] or sq.v[3]!=one.v[3]:
        raise Error("(-1)^2 != 1")
