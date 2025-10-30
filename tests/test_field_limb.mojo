from secp256k1.field_limb import fe_sub, fe_zero, fe_one, fe_sqr, fe_to_bytes32, fe_from_bytes32

fn main():
    # (-1) == p-1
    var m1 = fe_sub(fe_zero(), fe_one())

    # (-1)^2 == 1
    var sq = fe_sqr(m1)
    var one = fe_one()
    assert sq.v[0]==one.v[0] and sq.v[1]==one.v[1] and sq.v[2]==one.v[2] and sq.v[3]==one.v[3], "(-1)^2 != 1"

    # Round-trip bytes for (-1)
    var b = fe_to_bytes32(m1)
    var rt = fe_from_bytes32(b)
    assert rt.v[0]==m1.v[0] and rt.v[1]==m1.v[1] and rt.v[2]==m1.v[2] and rt.v[3]==m1.v[3], "from/to bytes mismatch"
