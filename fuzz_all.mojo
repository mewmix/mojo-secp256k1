from secp256k1.sign import ecdsa_sign_keccak
from keccak import keccak256_bytes

# ---- helpers ----

fn u64_to_be8(x: UInt64) -> List[Int]:
    var out = [0] * 8
    out[0] = Int((x >> 56) & UInt64(0xFF))
    out[1] = Int((x >> 48) & UInt64(0xFF))
    out[2] = Int((x >> 40) & UInt64(0xFF))
    out[3] = Int((x >> 32) & UInt64(0xFF))
    out[4] = Int((x >> 24) & UInt64(0xFF))
    out[5] = Int((x >> 16) & UInt64(0xFF))
    out[6] = Int((x >> 8)  & UInt64(0xFF))
    out[7] = Int(x & UInt64(0xFF))
    return out.copy()

# keccak-based PRNG: 32 bytes = keccak([tag] + i_be + seed_be)
fn prng32(tag: Int, iter_idx: Int, seed: UInt64) -> List[Int]:
    var inp = [0] * 17
    inp[0] = tag & 0xFF
    var i8 = u64_to_be8(UInt64(iter_idx))
    var s8 = u64_to_be8(seed)
    var k = 0
    while k < 8:
        inp[1 + k] = i8[k]
        inp[9 + k] = s8[k]
        k += 1
    return keccak256_bytes(inp, len(inp))

# ---- fuzzer ----

fn fuzz_ecdsa_sign(iterations: Int = 10000, seed: UInt64 = UInt64(0xABCDEF1234567890)):
    print("[fuzz_ecdsa_sign] START")
    var i = 0
    while i < iterations:
        var msg = prng32(0xA1, i, seed)
        var sk = prng32(0xB2, i, seed)

        try:
            _ = ecdsa_sign_keccak(msg, sk)
        except:
            pass

        if i % 1000 == 0:
            print("[fuzz_ecdsa_sign] Iteration", i)
        i += 1

    print("[fuzz_ecdsa_sign] COMPLETED")

from secp256k1 import ecdsa_verify
from secp256k1.sign import bytes_to_int_be
fn fuzz_ecdsa_verify(iterations: Int = 10000, seed: UInt64 = UInt64(0xABCDEF1234567890)):
    print("[fuzz_ecdsa_verify] START")
    var i = 0
    while i < iterations:
        var pk_x = prng32(0xC3, i, seed)
        var pk_y = prng32(0xC4, i, seed)
        var pk = List[Int](0x04)
        for i in range(32):
            pk.append(pk_x[i])
        for i in range(32):
            pk.append(pk_y[i])

        var msg = prng32(0xD4, i, seed)
        var r = prng32(0xE5, i, seed)
        var s = prng32(0xF6, i, seed)

        try:
            _ = ecdsa_verify(pk, msg, bytes_to_int_be(r), bytes_to_int_be(s))
        except:
            pass

        if i % 1000 == 0:
            print("[fuzz_ecdsa_verify] Iteration", i)
        i += 1

    print("[fuzz_ecdsa_verify] COMPLETED")

from secp256k1.sign import Point, point_add, point_double, point_mul, generator_point
fn fuzz_point_ops(iterations: Int = 10000, seed: UInt64 = UInt64(0xABCDEF1234567890)):
    print("[fuzz_point_ops] START")
    var i = 0
    while i < iterations:
        var p1_x = bytes_to_int_be(prng32(0xA1, i, seed))
        var p1_y = bytes_to_int_be(prng32(0xA2, i, seed))
        var p2_x = bytes_to_int_be(prng32(0xB1, i, seed))
        var p2_y = bytes_to_int_be(prng32(0xB2, i, seed))
        var k = bytes_to_int_be(prng32(0xC1, i, seed))

        var p1 = Point()
        p1.infinity = False
        p1.x = p1_x
        p1.y = p1_y

        var p2 = Point()
        p2.infinity = False
        p2.x = p2_x
        p2.y = p2_y

        try:
            _ = point_add(p1, p2)
        except:
            pass

        try:
            _ = point_double(p1)
        except:
            pass

        try:
            _ = point_mul(k, p1)
        except:
            pass

        if i % 1000 == 0:
            print("[fuzz_point_ops] Iteration", i)
        i += 1

    print("[fuzz_point_ops] COMPLETED")

from secp256k1.recover import ecdsa_recover_keccak
from secp256k1.sign import SigCompact

fn prng_byte(tag: Int, iter_idx: Int, seed: UInt64) -> Int:
    var b = prng32(tag, iter_idx, seed)
    return b[0]  # 0..255

fn fuzz_ecdsa_recover(iterations: Int = 10000, seed: UInt64 = UInt64(0xABCDEF1234567890)):
    print("[fuzz_ecdsa_recover] START")
    var i = 0
    while i < iterations:
        var msg = prng32(0xA1, i, seed)
        var sig = SigCompact()
        sig.r = prng32(0xB2, i, seed)
        sig.s = prng32(0xC3, i, seed)
        sig.v = prng_byte(0xD4, i, seed)  # 0..255

        fn _consume_point(p: Point): pass
        try:
            _consume_point(ecdsa_recover_keccak(msg, sig.r, sig.s, sig.v))
        except:
            pass

        if i % 1000 == 0:
            print("[fuzz_ecdsa_recover] Iteration", i)
        i += 1

    print("[fuzz_ecdsa_recover] COMPLETED")

fn main():
    fuzz_ecdsa_sign(10000)
    fuzz_ecdsa_verify(10000)
    fuzz_point_ops(10000)
    fuzz_ecdsa_recover(10000)
