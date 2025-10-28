
from secp256k1.sign import (
    CURVE_N, Point, SigCompact, bytes_to_int_be, int_to_bytes32_be, pubkey_from_seckey, pubkey_serialize_uncompressed_xy
)
from secp256k1.recover import ecdsa_recover_keccak, pub_uncompressed_xy
from decimojo import BigInt

fn test_invalid_signature_random_bytes():
    var msg = [1] * 32
    var sig = SigCompact()
    for i in range(32):
        sig.r[i] = 0xFF
        sig.s[i] = 0xFF
    sig.v = 27
    var failed = False
    try:
        var _ = ecdsa_recover_keccak(msg, sig.r, sig.s, sig.v)
    except:
        failed = True
        pass
    if not failed:
        print("FAIL: random bytes signature should not recover a key")

fn test_signature_r0_s0():
    var msg = [1] * 32
    var sig = SigCompact()
    sig.r = [0] * 32
    sig.s = [0] * 32
    sig.v = 27
    var failed = False
    try:
        var _ = ecdsa_recover_keccak(msg, sig.r, sig.s, sig.v)
    except:
        failed = True
        pass
    if not failed:
        print("FAIL: r=0, s=0 signature should not recover a key")

fn test_signature_rn_sn() raises:
    var msg = [1] * 32
    var n_bytes = int_to_bytes32_be(CURVE_N)
    var sig = SigCompact()
    sig.r = n_bytes.copy()
    sig.s = n_bytes.copy()
    sig.v = 27
    var failed = False
    try:
        var _ = ecdsa_recover_keccak(msg, sig.r, sig.s, sig.v)
    except:
        failed = True
        pass
    if not failed:
        print("FAIL: r=n, s=n signature should not recover a key")

fn test_message_all_zeros():
    var msg = [0] * 32
    var sig = SigCompact()
    for i in range(32):
        sig.r[i] = 0x30
        sig.s[i] = 0x30
    sig.v = 27
    var failed = False
    try:
        var _ = ecdsa_recover_keccak(msg, sig.r, sig.s, sig.v)
    except:
        failed = True
        pass
    if not failed:
        print("FAIL: all-zeros message with random sig should not recover a key")

fn test_non_canonical_signature_high_s() raises:
    var msg = [1] * 32
    var sig = SigCompact()
    sig.r = int_to_bytes32_be(BigInt(1))
    sig.s = int_to_bytes32_be(CURVE_N - BigInt(1))
    sig.v = 27
    var failed = False
    try:
        var _ = ecdsa_recover_keccak(msg, sig.r, sig.s, sig.v)
    except:
        failed = True
        pass
    if not failed:
        print("FAIL: high-s signature should not recover a key")

fn test_recovery_invalid_v() raises:
    var msg = [1] * 32
    var sig = SigCompact()
    sig.r = int_to_bytes32_be(BigInt(1))
    sig.s = int_to_bytes32_be(BigInt(1))
    sig.v = 31  # Invalid v
    var failed = False
    try:
        var _ = ecdsa_recover_keccak(msg, sig.r, sig.s, sig.v)
    except:
        failed = True
        pass
    if not failed:
        print("FAIL: invalid v should not recover a key")

fn main() raises:
    test_invalid_signature_random_bytes()
    test_signature_r0_s0()
    test_signature_rn_sn()
    test_message_all_zeros()
    test_non_canonical_signature_high_s()
    test_recovery_invalid_v()
    print("Adversarial ECDSA tests passed.")

