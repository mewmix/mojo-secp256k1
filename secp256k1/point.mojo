from .fe import (
    Fe,
    fe_zero,
    fe_one,
    fe_neg,
    fe_copy,
    fe_add,
    fe_sub,
    fe_mul,
    fe_sqr,
    fe_inv,
    fe_from_bytes,
    G_X,
    G_Y,
    fe_is_zero,
    fe_equal,
    fe_from_u64,
)


@always_inline
fn fe_double(a: Fe) -> Fe:
    return fe_add(a, a)


@always_inline
fn fe_triple(a: Fe) -> Fe:
    return fe_add(fe_double(a), a)


@always_inline
fn fe_quadruple(a: Fe) -> Fe:
    return fe_double(fe_double(a))

struct Affine(Movable):
    var x: Fe
    var y: Fe
    var infinity: Bool

    fn __init__(out self):
        self.x = fe_zero()
        self.y = fe_zero()
        self.infinity = True

struct Jacobian(Movable):
    var x: Fe
    var y: Fe
    var z: Fe
    var infinity: Bool

    fn __init__(out self):
        self.x = fe_zero()
        self.y = fe_zero()
        self.z = fe_zero()
        self.infinity = True

fn generator_affine() raises -> Affine:
    var p = Affine()
    p.x = fe_from_bytes(G_X)
    p.y = fe_from_bytes(G_Y)
    p.infinity = False
    return p^

fn affine_to_jacobian(p: Affine) -> Jacobian:
    var res = Jacobian()
    if p.infinity:
        res.infinity = True
    else:
        res.x = p.x
        res.y = p.y
        res.z = fe_one()
        res.infinity = False
    return res^

fn jacobian_to_affine(p: Jacobian) raises -> Affine:
    if p.infinity:
        var res = Affine()
        res.infinity = True
        return res^

    var z_inv = fe_inv(p.z)
    var z_inv_sq = fe_sqr(z_inv)
    var x = fe_mul(p.x, z_inv_sq)
    var y = fe_mul(p.y, fe_mul(z_inv_sq, z_inv))

    var res = Affine()
    res.x = x^
    res.y = y^
    res.infinity = False
    return res^

@always_inline
fn jacobian_double_inplace(inout p: Jacobian) raises:
    if p.infinity or fe_is_zero(p.y):
        p.infinity = True
        return

    var xx = fe_sqr(p.x)
    var yy = fe_sqr(p.y)
    var yyyy = fe_sqr(yy)
    var zz = fe_sqr(p.z)

    var s = fe_mul(p.x, yy)
    s = fe_quadruple(s)

    var m = fe_triple(xx)

    var t = fe_sqr(m)
    var two_s = fe_double(s)
    var new_x = fe_sub(t, two_s)

    var eight_yyyy = fe_double(yyyy)
    eight_yyyy = fe_double(eight_yyyy)
    eight_yyyy = fe_double(eight_yyyy)
    var new_y = fe_sub(fe_mul(m, fe_sub(s, new_x)), eight_yyyy)

    var z_plus = fe_add(p.y, p.z)
    var new_z = fe_sqr(z_plus)
    new_z = fe_sub(new_z, yy)
    new_z = fe_sub(new_z, zz)

    p.x = new_x
    p.y = new_y
    p.z = new_z
    p.infinity = False


fn jacobian_double(p: Jacobian) raises -> Jacobian:
    var res = p
    jacobian_double_inplace(res)
    return res^

@always_inline
fn jacobian_add(p1: Jacobian, p2: Jacobian) raises -> Jacobian:
    if p1.infinity:
        return p2^
    if p2.infinity:
        return p1^

    var z1z1 = fe_sqr(p1.z)
    var z2z2 = fe_sqr(p2.z)
    var u1 = fe_mul(p1.x, z2z2)
    var u2 = fe_mul(p2.x, z1z1)
    var s1 = fe_mul(fe_mul(p1.y, z2z2), p2.z)
    var s2 = fe_mul(fe_mul(p2.y, z1z1), p1.z)

    if fe_equal(u1, u2):
        if not fe_equal(s1, s2):
            var res = Jacobian()
            res.infinity = True
            return res^
        else:
            return jacobian_double(p1)

    var h = fe_sub(u2, u1)
    var r = fe_sub(s2, s1)
    var h2 = fe_sqr(h)
    var h3 = fe_mul(h2, h)
    var u1_h2 = fe_mul(u1, h2)

    var x = fe_sub(fe_sub(fe_sqr(r), h3), fe_mul(fe_from_u64(2), u1_h2))
    var y = fe_sub(fe_mul(r, fe_sub(u1_h2, x)), fe_mul(s1, h3))
    var z = fe_mul(fe_mul(h, p1.z), p2.z)

    var res = Jacobian()
    res.x = x^
    res.y = y^
    res.z = z^
    res.infinity = False
    return res^

@always_inline
fn jacobian_mixed_add_inplace(inout p1: Jacobian, p2: Affine) raises:
    if p2.infinity:
        return
    if p1.infinity:
        p1.x = p2.x
        p1.y = p2.y
        p1.z = fe_one()
        p1.infinity = False
        return

    var z1z1 = fe_sqr(p1.z)
    var u2 = fe_mul(p2.x, z1z1)
    var s2 = fe_mul(fe_mul(p2.y, p1.z), z1z1)

    if fe_equal(p1.x, u2):
        var r = fe_sub(s2, p1.y)
        if fe_is_zero(r):
            jacobian_double_inplace(p1)
        else:
            p1.infinity = True
        return

    var h = fe_sub(u2, p1.x)
    var hh = fe_sqr(h)
    var i = fe_quadruple(hh)
    var j = fe_mul(h, i)
    var r = fe_double(fe_sub(s2, p1.y))
    var v = fe_mul(p1.x, i)

    var new_x = fe_sub(fe_sqr(r), fe_add(j, fe_double(v)))

    var ry = fe_mul(p1.y, j)
    ry = fe_double(ry)
    var new_y = fe_sub(fe_mul(r, fe_sub(v, new_x)), ry)

    var new_z = fe_add(p1.z, h)
    new_z = fe_sqr(new_z)
    new_z = fe_sub(new_z, z1z1)
    new_z = fe_sub(new_z, hh)

    p1.x = new_x
    p1.y = new_y
    p1.z = new_z
    p1.infinity = False


fn jacobian_mixed_add(p1: Jacobian, p2: Affine) raises -> Jacobian:
    var res = p1
    jacobian_mixed_add_inplace(res, p2)
    return res^

fn point_infinity_jac() -> Jacobian:
    var p = Jacobian()
    p.infinity = True
    return p^
