"""Test suite for secp256k1 field, scalar, and signing operations."""

from decimojo import BigInt
from secp256k1.fe import (
    Fe, fe_zero, fe_one, fe_add, fe_sub, fe_mul, fe_sqr, fe_neg, fe_inv,
    fe_normalize_strong, fe_from_bytes32, fe_to_bytes32
)
from secp256k1.sc import (
    Sc, sc_zero, sc_from_bytes32, sc_to_bytes32, sc_add, sc_mul, 
    sc_mul_u64, sc_neg, sc_sub, sc_inv, CURVE_N
)
from secp256k1.sign import (
    ecdsa_sign_keccak, eth_personal_hash, bytes_to_int_be, int_to_bytes32_be
)



fn assert_fe_equal(a: Fe, expected: Int, msg: String) raises:
    """Asserts a field element equals an integer."""
    var bytes_a = fe_to_bytes32(a)
    var val_a = bytes_to_int_be(bytes_a)
    if val_a != expected:
        raise Error("Assertion failed: " + msg +
                    " - expected " + String(expected) + ", got " + String(val_a))

fn fe_from_int(val: Int) raises -> Fe:
    """Creates a field element from an integer."""
    return fe_from_bytes32(int_to_bytes32_be(val))

fn test_field_basic() raises:
    print("Testing field basic operations...")
    
    # Test zero and one
    var zero = fe_zero()
    assert_fe_equal(zero, 0, "fe_zero should be 0")
    
    var one = fe_one()
    assert_fe_equal(one, 1, "fe_one should be 1")
    
    # Test addition
    var a = fe_from_int(42)
    var b = fe_from_int(58)
    var sum = fe_add(a, b)
    assert_fe_equal(sum, 100, "42 + 58 should be 100")
    
    # Test subtraction
    var diff = fe_sub(b, a)
    assert_fe_equal(diff, 16, "58 - 42 should be 16")
    
    # Test negation
    var neg_a = fe_neg(a)
    var check_zero = fe_add(a, neg_a)
    assert_fe_equal(check_zero, 0, "a + (-a) should be 0")
    
    # Test multiplication
    var prod = fe_mul(a, b)
    assert_fe_equal(prod, 2436, "42 * 58 should be 2436")
    
    # Test squaring
    var sqr = fe_sqr(a)
    assert_fe_equal(sqr, 1764, "42^2 should be 1764")
    
    print("✓ Field basic operations passed")


fn test_field_modular() raises:
    print("Testing field modular arithmetic...")
    
    # p = 2^256 - 2^32 - 977
    var p_str = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F"

    fn hex_to_bytes(hex_str: String) -> List[Int]:
        var bytes = List[Int]()
        for i in range(0, len(hex_str), 2):
            var s = hex_str[i:i+2]
            var byte: Int = 0
            var c1 = s[0]
            var c2 = s[1]

            if '0' <= c1 <= '9': byte += (ord(c1) - ord('0')) * 16
            elif 'a' <= c1 <= 'f': byte += (ord(c1) - ord('a') + 10) * 16
            elif 'A' <= c1 <= 'F': byte += (ord(c1) - ord('A') + 10) * 16

            if '0' <= c2 <= '9': byte += ord(c2) - ord('0')
            elif 'a' <= c2 <= 'f': byte += ord(c2) - ord('a') + 10
            elif 'A' <= c2 <= 'F': byte += ord(c2) - ord('A') + 10

            bytes.append(byte)
        return bytes.copy()

    var p_bytes = hex_to_bytes(p_str)
    var P = bytes_to_int_be(p_bytes)

    # Test modular reduction on large values
    var large_bytes = int_to_bytes32_be(P + 123)
    var large = fe_from_bytes32(large_bytes)
    assert_fe_equal(large, 123, "Should reduce mod p")
    
    # Test wraparound subtraction
    var a = fe_from_int(10)
    var b = fe_from_int(20)
    var diff = fe_sub(a, b)

    fn assert_fe_equal_bigint(a: Fe, expected: BigInt, msg: String) raises:
        """Asserts a field element equals a BigInt."""
        var bytes_a = fe_to_bytes32(a)
        var val_a = bytes_to_int_be(bytes_a)
        if val_a != expected:
            raise Error("Assertion failed: " + msg +
                        " - expected " + String(expected) + ", got " + String(val_a))

    assert_fe_equal_bigint(diff, P - 10, "10 - 20 mod p should wrap")
    
    # Test inverse
    var x = fe_from_int(7)
    var xinv = fe_inv(x)
    var prod = fe_mul(x, xinv)
    assert_fe_equal(prod, 1, "x * x^-1 should be 1")
    
    # Test normalization (now a no-op, but test for API compatibility)
    var unnorm_bytes = int_to_bytes32_be(P + 123456)
    var unnorm = fe_from_bytes32(unnorm_bytes)
    fe_normalize_strong(unnorm) # should be a no-op
    assert_fe_equal(unnorm, 123456, "Normalization should handle reduction")
    
    print("✓ Field modular arithmetic passed")


fn assert_sc_equal(a: Sc, expected: Int, msg: String) raises:
    """Asserts a scalar equals an integer."""
    var bytes_a = sc_to_bytes32(a)
    var val_a = bytes_to_int_be(bytes_a)
    if val_a != expected:
        raise Error("Assertion failed: " + msg +
                    " - expected " + String(expected) + ", got " + String(val_a))

fn sc_from_int(val: Int) raises -> Sc:
    """Creates a scalar from an integer."""
    return sc_from_bytes32(int_to_bytes32_be(val))

fn test_scalar_basic() raises:
    print("Testing scalar basic operations...")
    
    # Test zero
    var zero = sc_zero()
    assert_sc_equal(zero, 0, "sc_zero should be 0")
    
    # Test addition
    var a = sc_from_int(100)
    var b = sc_from_int(200)
    var sum = sc_add(a, b)
    assert_sc_equal(sum, 300, "100 + 200 should be 300")
    
    # Test subtraction
    var diff = sc_sub(b, a)
    assert_sc_equal(diff, 100, "200 - 100 should be 100")
    
    # Test negation
    var neg_a = sc_neg(a)
    var check = sc_add(a, neg_a)
    assert_sc_equal(check, 0, "a + (-a) should be 0")
    
    # Test multiplication
    var prod = sc_mul(a, b)
    assert_sc_equal(prod, 20000, "100 * 200 should be 20000")
    
    # Test multiplication by u64
    var c = sc_from_int(50)
    var prod2 = sc_mul_u64(c, UInt64(3))
    assert_sc_equal(prod2, 150, "50 * 3 should be 150")
    
    print("✓ Scalar basic operations passed")


fn test_scalar_serialization() raises:
    print("Testing scalar serialization...")
    
    # Test bytes32 conversion round-trip
    var test_bytes = [0] * 32
    test_bytes[31] = 0x42
    test_bytes[30] = 0x01
    
    var sc = sc_from_bytes32(test_bytes)
    var bytes_out = sc_to_bytes32(sc)
    
    # Check round-trip
    for i in range(32):
        assert_true(bytes_out[i] == test_bytes[i], "Byte mismatch at position " + String(i))
    
    # Test with larger value
    var large_val = sc_from_int(0xDEADBEEF)
    var large_bytes = sc_to_bytes32(large_val)
    var large_back = sc_from_bytes32(large_bytes)
    assert_sc_equal(large_back, 0xDEADBEEF, "Large value round-trip failed")
    
    print("✓ Scalar serialization passed")


fn test_scalar_modular() raises:
    print("Testing scalar modular arithmetic...")
    
    # Test modular reduction
    var n_bytes = sc_to_bytes32(sc_from_int(0))
    var N = bytes_to_int_be(n_bytes)
    var large_val = N + 456
    var large_bytes = int_to_bytes32_be(large_val)
    var large = sc_from_bytes32(large_bytes)
    assert_sc_equal(large, 456, "Should reduce mod n")
    
    # Test inverse
    var x = sc_from_int(13)
    var xinv = sc_inv(x)
    var prod = sc_mul(x, xinv)
    assert_sc_equal(prod, 1, "x * x^-1 should be 1 mod n")
    
    print("✓ Scalar modular arithmetic passed")


fn test_signing_helpers() raises:
    print("Testing signing helper functions...")
    
    # Test bytes_to_int_be
    var test_bytes = [0] * 32
    test_bytes[31] = 0xFF
    test_bytes[30] = 0x00
    test_bytes[29] = 0x00
    test_bytes[28] = 0x00
    var val = bytes_to_int_be(test_bytes)
    assert_true(val == 0xFF, "bytes_to_int_be failed")
    
    # Test int_to_bytes32_be round-trip
    var test_val = Int(0x123456789ABCDEF)
    var bytes = int_to_bytes32_be(test_val)
    var back = bytes_to_int_be(bytes)
    assert_true(back == test_val, "int/bytes round-trip failed")
    
    # Test eth_personal_hash (just ensure it runs)
    var msg = [72, 101, 108, 108, 111]  # "Hello"
    var hash = eth_personal_hash(msg)
    assert_true(len(hash) == 32, "Hash should be 32 bytes")
    
    print("✓ Signing helpers passed")


fn test_ecdsa_sign() raises:
    print("Testing ECDSA signing...")
    
    # Test vector: sign a simple message with a known key
    var msg32 = [0] * 32
    msg32[31] = 0x01  # Simple message
    
    var seckey32 = [0] * 32
    seckey32[31] = 0x01  # Simple private key (not secure, just for testing)
    
    try:
        var sig = ecdsa_sign_keccak(msg32, seckey32)
        
        # Basic validation
        assert_true(len(sig.r) == 32, "r should be 32 bytes")
        assert_true(len(sig.s) == 32, "s should be 32 bytes")
        assert_true(sig.v == 27 or sig.v == 28, "v should be 27 or 28")
        
        # Ensure r and s are non-zero
        var r_val = bytes_to_int_be(sig.r)
        var s_val = bytes_to_int_be(sig.s)
        assert_true(r_val > 0, "r should be non-zero")
        assert_true(s_val > 0, "s should be non-zero")
        assert_true(r_val < CURVE_N, "r should be less than n")
        assert_true(s_val < CURVE_N, "s should be less than n")
        
        print("✓ ECDSA signing passed")
    except e:
        print("✗ ECDSA signing failed: " + String(e))
        raise e


fn assert_true(condition: Bool, message: String) raises:
    if not condition:
        raise Error("Assertion failed: " + message)


fn main() raises:
    print("Running secp256k1 test suite...")
    print()
    
    test_field_basic()
    test_field_modular()
    test_scalar_basic()
    test_scalar_serialization()
    test_scalar_modular()
    test_signing_helpers()
    test_ecdsa_sign()
    
    print()
    print("All tests passed! ✓")
