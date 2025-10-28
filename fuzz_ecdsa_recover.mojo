from secp256k1.sign import SigCompact 
from secp256k1.sign import Point
from secp256k1.recover import ecdsa_recover_keccak
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

fn prng_byte(tag: Int, iter_idx: Int, seed: UInt64) -> Int:
    var b = prng32(tag, iter_idx, seed)
    return b[0]  # 0..255

# ---- fuzzer ----

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
    fuzz_ecdsa_recover(10000)