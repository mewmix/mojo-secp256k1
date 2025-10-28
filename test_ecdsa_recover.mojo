"""Pure Mojo round-trip: sign -> recover -> compare with pubkey_from_seckey."""

from secp256k1.sign import ecdsa_sign_keccak, pubkey_from_seckey, pubkey_serialize_uncompressed_xy
from secp256k1.recover import ecdsa_recover_keccak, pub_uncompressed_xy
from keccak.keccak import keccak256_bytes

fn hex_nibble(c: Int) -> Int:
    if 48 <= c <= 57: return c - 48
    if 97 <= c <= 102: return c - 87
    if 65 <= c <= 70: return c - 55
    return 0

fn hex_to_bytes(hex: String) -> List[Int]:
    var s = hex
    if len(s) >= 2 and s[0] == '0' and (s[1] == 'x' or s[1] == 'X'):
        s = s[2:]
    var out = List[Int]()
    var i = 0
    while i < len(s):
        var hi = hex_nibble(ord(s[i]))
        var lo = hex_nibble(ord(s[i+1]))
        out.append(((hi << 4) | lo) & 0xFF)
        i += 2
    return out.copy()

fn assert_eq_lists(a: List[Int], b: List[Int], msg: String) raises:
    if len(a) != len(b):
        raise Error(msg + " (len mismatch)")
    var i = 0
    while i < len(a):
        if a[i] != b[i]:
            raise Error(msg + " @ " + String(i))
        i += 1

fn test_case(seckey_hex: String, msg: List[Int]) raises:
    var sk = hex_to_bytes(seckey_hex)
    var pub_ref = pubkey_from_seckey(sk)
    var pub_ref_xy = pubkey_serialize_uncompressed_xy(pub_ref)

    var z = keccak256_bytes(msg, len(msg))
    var sig = ecdsa_sign_keccak(z, sk)

    var rec = ecdsa_recover_keccak(z, sig.r, sig.s, sig.v)
    var rec_xy = pub_uncompressed_xy(rec)

    assert_eq_lists(rec_xy, pub_ref_xy, "recovered pubkey mismatch")

fn main() raises:
    var keys = [
        # 32-byte scalar = 0x...01 (64 hex digits)
        "0000000000000000000000000000000000000000000000000000000000000001",
        "4c0883a69102937d6231471b5dbb6204fe512961708279e3f6c7b1e3d5f8e7f8",
        "c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721"
    ]
    var msgs = [
        [0x41,0x42,0x43],                 # "ABC"
        [0x73,0x61,0x6d,0x70,0x6c,0x65],  # "sample"
        [0x74,0x65,0x73,0x74],            # "test"
        [0x45,0x74,0x68,0x65,0x72,0x65,0x75,0x6d] # "Ethereum"
    ]
    var i = 0
    while i < len(keys):
        var j = 0
        while j < len(msgs):
            test_case(keys[i], msgs[j])
            j += 1
        i += 1
    print("PASS: pure-Mojo recover matched pubkeys for all cases")
