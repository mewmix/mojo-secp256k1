from collections.inline_array import InlineArray
from .fe import Fe, fe_zero, fe_one, fe_neg
from .sc import Sc, sc_is_zero, sc_is_odd, sc_shr1, sc_add_u64, sc_sub, sc_from_u64
from .point import (
    Affine,
    Jacobian,
    generator_affine,
    affine_to_jacobian,
    jacobian_to_affine,
    jacobian_double,
    jacobian_double_inplace,
    jacobian_add,
    jacobian_mixed_add,
    jacobian_mixed_add_inplace,
    point_infinity_jac,
)
from .utils import fe_cmov, ct_cmov_u64

alias W = 12
alias TBL_SIZE = 1 << (W - 1)
var G_TABLE = InlineArray[Affine, TBL_SIZE]()
var G_INIT = False

fn fixed_base_init() raises:
    if G_INIT: return
    var G = generator_affine()
    var twoG = jacobian_double(affine_to_jacobian(G))
    var twoG_aff = jacobian_to_affine(twoG)
    G_TABLE[0] = G
    var i = 1
    while i < TBL_SIZE:
        var jprev = affine_to_jacobian(G_TABLE[i-1])
        G_TABLE[i] = jacobian_to_affine(jacobian_add(jprev, affine_to_jacobian(twoG_aff)))
        i += 1
    G_INIT = True

fn wnaf_encode(out out_digits: InlineArray[Int8, 257], k_in: Sc) -> Int:
    var k = k_in.copy()
    var len = 0
    while not sc_is_zero(k):
        var d: Int8 = 0
        if sc_is_odd(k):
            var mw = k.v[0] & (UInt64((1 << W) - 1))
            if mw > UInt64(1 << (W - 1)):
                d = Int8(Int(mw) - (1 << W))
                k = sc_add_u64(k, UInt64(-Int(d)))
            else:
                d = Int8(Int(mw))
                k = sc_sub(k, sc_from_u64(UInt64(d)))
        out_digits[len] = d
        len += 1
        var tmp = Sc()
        sc_shr1(tmp, k)
        k = tmp^
    return len

fn tbl_select_abs(out dst: Affine, abs_digit: Int) raises:
    var idx = (abs_digit - 1) >> 1
    dst.x = fe_zero()
    dst.y = fe_one()
    dst.infinity = True

    var i = 0
    while i < TBL_SIZE:
        let choose = UInt64(i == idx)
        fe_cmov(dst.x, dst.x, G_TABLE[i].x, choose)
        fe_cmov(dst.y, dst.y, G_TABLE[i].y, choose)
        var inf_u64 = ct_cmov_u64(UInt64(dst.infinity), UInt64(G_TABLE[i].infinity), choose)
        dst.infinity = (inf_u64 != 0)
        i += 1

fn kG_wnaf(out R: Jacobian, k: Sc) raises:
    if not G_INIT: fixed_base_init()
    var digits = InlineArray[Int8, 257](repeating: 0)
    let n = wnaf_encode(digits, k)
    R = point_infinity_jac()
    var i = n - 1
    while i >= 0:
        jacobian_double_inplace(R)
        let d = digits[i]
        let neg = (d < 0)
        let ad = Int( (d < 0) ? -d : d )
        if ad != 0:
            var P: Affine
            tbl_select_abs(P, ad)
            if neg: P.y = fe_neg(P.y)
            jacobian_mixed_add_inplace(R, P)
        i -= 1
