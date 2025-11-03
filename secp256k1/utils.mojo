from collections.inline_array import InlineArray
from .fe import Fe
from .point import Point

@always_inline
fn ct_mask64(c: UInt64) -> UInt64:
    return 0 - c

@always_inline
fn ct_cmov_u64(a: UInt64, b: UInt64, c: UInt64) -> UInt64:
    var m = ct_mask64(c)
    return (a & ~m) | (b & m)

fn fe_cmov(out r: Fe, a: Fe, b: Fe, c: UInt64):
    var i = 0
    while i < 4:
        r.value[i] = ct_cmov_u64(a.value[i], b.value[i], c)
        i += 1
