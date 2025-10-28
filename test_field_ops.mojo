from decimojo import BigInt
from secp256k1.sign import (
    FIELD_P,
    mod_positive,
    mod_inv,
)

from python import Python

fn test_add() raises:
    print("Testing add...")
    var a = BigInt(1)
    var b = BigInt(2)
    var c = a + b
    if c != BigInt(3):
        raise Error("1 + 2 != 3")

    a = FIELD_P - BigInt(1)
    b = BigInt(2)
    c = mod_positive(a + b, FIELD_P)
    if c != BigInt(1):
        raise Error("(P-1) + 2 != 1")

    a = BigInt(0)
    b = BigInt(1)
    c = mod_positive(a + b, FIELD_P)
    if c != BigInt(1):
        raise Error("0 + 1 != 1")

    a = FIELD_P
    b = BigInt(1)
    c = mod_positive(a + b, FIELD_P)
    if c != BigInt(1):
        raise Error("P + 1 != 1")

    a = FIELD_P + BigInt(1)
    b = BigInt(1)
    c = mod_positive(a + b, FIELD_P)
    if c != BigInt(2):
        raise Error("(P+1) + 1 != 2")

    var random = Python.import_module("random")
    for _ in range(100):
        var r1 = BigInt(Int(random.randint(0, 1_000_000_000)))
        var r2 = BigInt(Int(random.randint(0, 1_000_000_000)))
        var r3 = mod_positive(r1 + r2, FIELD_P)
        var r4 = mod_positive(mod_positive(r1, FIELD_P) + mod_positive(r2, FIELD_P), FIELD_P)
        if r3 != r4:
            raise Error("random add failed")

    print("...add OK")

fn test_sub() raises:
    print("Testing sub...")
    var a = BigInt(3)
    var b = BigInt(2)
    var c = a - b
    if c != BigInt(1):
        raise Error("3 - 2 != 1")

    a = BigInt(1)
    b = BigInt(2)
    c = mod_positive(a - b, FIELD_P)
    if c != FIELD_P - BigInt(1):
        raise Error("1 - 2 != P-1")
    print("...sub OK")

fn test_mul() raises:
    print("Testing mul...")
    var a = BigInt(2)
    var b = BigInt(3)
    var c = a * b
    if c != BigInt(6):
        raise Error("2 * 3 != 6")

    a = FIELD_P - BigInt(1)
    b = BigInt(2)
    c = mod_positive(a * b, FIELD_P)
    if c != FIELD_P - BigInt(2):
        raise Error("(P-1) * 2 != P-2")

    a = BigInt(0)
    b = BigInt(1)
    c = mod_positive(a * b, FIELD_P)
    if c != BigInt(0):
        raise Error("0 * 1 != 0")

    a = FIELD_P
    b = BigInt(2)
    c = mod_positive(a * b, FIELD_P)
    if c != BigInt(0):
        raise Error("P * 2 != 0")

    var random = Python.import_module("random")
    for _ in range(100):
        var r1 = BigInt(Int(random.randint(0, 1_000_000_000)))
        var r2 = BigInt(Int(random.randint(0, 1_000_000_000)))
        var r3 = mod_positive(r1 * r2, FIELD_P)
        var r4 = mod_positive(mod_positive(r1, FIELD_P) * mod_positive(r2, FIELD_P), FIELD_P)
        if r3 != r4:
            raise Error("random mul failed")

    print("...mul OK")

fn test_sqr() raises:
    print("Testing sqr...")
    var a = BigInt(3)
    var c = a * a
    if c != BigInt(9):
        raise Error("3*3 != 9")

    a = FIELD_P - BigInt(1)
    c = mod_positive(a * a, FIELD_P)
    if c != BigInt(1):
        raise Error("(P-1)^2 != 1")
    print("...sqr OK")

fn test_inv() raises:
    print("Testing inv...")
    var a = BigInt(2)
    var inv = mod_inv(a, FIELD_P)
    var c = mod_positive(a * inv, FIELD_P)
    if c != BigInt(1):
        raise Error("2 * mod_inv(2) != 1")
    print("...inv OK")

fn main() raises:
    test_add()
    test_sub()
    test_mul()
    test_sqr()
    test_inv()
    print("All field op tests passed.")
