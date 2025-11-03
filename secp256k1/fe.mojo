from collections.inline_array import InlineArray
from .field_limb import (
    Fe,
    fe_clone,
    fe_zero as limb_fe_zero,
    fe_one as limb_fe_one,
    fe_add as limb_fe_add,
    fe_sub as limb_fe_sub,
    fe_neg as limb_fe_neg,
    fe_mul as limb_fe_mul,
    fe_sqr as limb_fe_sqr,
    fe_inv as limb_fe_inv,
    fe_from_limbs,
    fe_from_bytes32 as limb_fe_from_bytes32,
    fe_to_bytes32 as limb_fe_to_bytes32,
    fe_normalize_strong as limb_fe_normalize_strong,
)

alias INT64_MAX = UInt64(0x7FFFFFFFFFFFFFFF)

@always_inline
fn fe_zero() -> Fe:
    return limb_fe_zero()

@always_inline
fn fe_one() -> Fe:
    return limb_fe_one()

@always_inline
fn fe_copy(a: Fe) -> Fe:
    return fe_clone(a)

@always_inline
fn fe_add(a: Fe, b: Fe) -> Fe:
    return limb_fe_add(a, b)

@always_inline
fn fe_sub(a: Fe, b: Fe) -> Fe:
    return limb_fe_sub(a, b)

@always_inline
fn fe_neg(a: Fe) -> Fe:
    return limb_fe_neg(a)

fn fe_mul(a: Fe, b: Fe) raises -> Fe:
    return limb_fe_mul(a, b)

fn fe_sqr(a: Fe) raises -> Fe:
    return limb_fe_sqr(a)

fn fe_inv(a: Fe) raises -> Fe:
    return limb_fe_inv(a)

fn fe_normalize_strong(mut a: Fe) raises:
    var normalized = limb_fe_normalize_strong(a)
    a.v = normalized.v

@always_inline
fn fe_is_zero(a: Fe) -> Bool:
    return a.v[0] == 0 and a.v[1] == 0 and a.v[2] == 0 and a.v[3] == 0

@always_inline
fn fe_equal(a: Fe, b: Fe) -> Bool:
    return (
        a.v[0] == b.v[0]
        and a.v[1] == b.v[1]
        and a.v[2] == b.v[2]
        and a.v[3] == b.v[3]
    )

@always_inline
fn fe_from_u64(val: UInt64) -> Fe:
    return fe_from_limbs(InlineArray[UInt64,4](val, 0, 0, 0))

fn _fe_from_int(value: Int) raises -> Fe:
    if value < 0:
        raise Error("_fe_from_int expects a non-negative value")
    return fe_from_u64(UInt64(value))

fn _fe_to_int(a: Fe) raises -> Int:
    if a.v[1] != UInt64(0) or a.v[2] != UInt64(0) or a.v[3] != UInt64(0):
        raise Error("field element does not fit in Int")
    if a.v[0] > INT64_MAX:
        raise Error("field element exceeds Int range")
    return Int(a.v[0])

fn fe_from_bytes(bytes: List[Int]) raises -> Fe:
    if len(bytes) != 32:
        raise Error("fe_from_bytes expects 32 bytes")
    return limb_fe_from_bytes32(bytes)

fn fe_to_bytes(a: Fe) -> List[Int]:
    return limb_fe_to_bytes32(a)

@always_inline
fn fe_is_odd(a: Fe) -> Bool:
    return (a.v[0] & UInt64(1)) == UInt64(1)

alias G_X = [
    0x79, 0xBE, 0x66, 0x7E, 0xF9, 0xDC, 0xBB, 0xAC, 0x55, 0xA0, 0x62, 0x95,
    0xCE, 0x87, 0x0B, 0x07, 0x02, 0x9B, 0xFC, 0xDB, 0x2D, 0xCE, 0x28, 0xD9,
    0x59, 0xF2, 0x81, 0x5B, 0x16, 0xF8, 0x17, 0x98
]

alias G_Y = [
    0x48, 0x3A, 0xDA, 0x77, 0x26, 0xA3, 0xC4, 0x65, 0x5D, 0x04, 0xFB, 0xFC,
    0x0E, 0x11, 0x08, 0xA8, 0xFD, 0x17, 0xB4, 0x48, 0xA6, 0x85, 0x54, 0x19,
    0x9C, 0x47, 0xD0, 0x8F, 0xFB, 0x10, 0xD4, 0xB8
]
