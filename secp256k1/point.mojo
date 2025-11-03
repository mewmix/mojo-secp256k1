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

fn jacobian_double(p: Jacobian) raises -> Jacobian:
    if p.infinity or fe_is_zero(p.y):
        var res = Jacobian()
        res.infinity = True
        return res^

    var y2 = fe_sqr(p.y)
    var s = fe_mul(fe_mul(fe_from_u64(4), p.x), y2)
    var m = fe_mul(fe_from_u64(3), fe_sqr(p.x))
    var x = fe_sub(fe_sqr(m), fe_mul(fe_from_u64(2), s))
    var y = fe_sub(fe_mul(m, fe_sub(s, x)), fe_mul(fe_from_u64(8), fe_sqr(y2)))
    var z = fe_mul(fe_mul(fe_from_u64(2), p.y), p.z)

    var res = Jacobian()
    res.x = x^
    res.y = y^
    res.z = z^
    res.infinity = False
    return res^

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

fn jacobian_mixed_add(p1: Jacobian, p2: Affine) raises -> Jacobian:
    if p1.infinity:
        return affine_to_jacobian(p2)
    if p2.infinity:
        return p1^

    var z1z1 = fe_sqr(p1.z)
    var u2 = p2.x
    var s2 = p2.y
    var u1 = fe_mul(p1.x, fe_one())
    var s1 = fe_mul(p1.y, fe_one())

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
    var z = fe_mul(h, p1.z)

    var res = Jacobian()
    res.x = x^
    res.y = y^
    res.z = z^
    res.infinity = False
    return res^

fn point_infinity_jac() -> Jacobian:
    var p = Jacobian()
    p.infinity = True
    return p^
