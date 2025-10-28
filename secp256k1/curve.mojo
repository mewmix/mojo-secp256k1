from decimojo import BigInt
from .sign import (
    B,
    FIELD_P,
    mod_positive,
    Point,
)

fn point_is_on_curve(p: Point) raises -> Bool:
    if p.infinity:
        return True
    var y2 = mod_positive(p.y.__mul__(p.y), FIELD_P)
    var x2 = mod_positive(p.x.__mul__(p.x), FIELD_P)
    var x3 = mod_positive(x2.__mul__(p.x), FIELD_P)
    return mod_positive(y2 - (x3 + B), FIELD_P) == BigInt(0)
