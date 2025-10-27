from secp256k1.rfc6979 import rfc6979_sha256
from secp256k1.sha256 import sha256_bytes


fn from_hex32(hex_str: String) -> List[Int]:
    var out = [0] * 32
    var byte_index = 32 - (len(hex_str) // 2)
    var i = 0
    while i < len(hex_str):
        var hi = hex_val(ord(hex_str[i]))
        var lo = hex_val(ord(hex_str[i + 1]))
        out[byte_index] = (hi << 4) | lo
        byte_index += 1
        i += 2
    return out.copy()


fn hex_val(c: Int) -> Int:
    if 48 <= c <= 57:
        return c - 48
    if 97 <= c <= 102:
        return c - 87
    if 65 <= c <= 70:
        return c - 55
    return 0


fn assert_eq32(a: List[Int], b: List[Int], msg: String) raises:
    for i in range(32):
        if a[i] != b[i]:
            raise Error(msg + " @ " + String(i))


fn test_sample() raises:
    var sk = from_hex32("C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721")
    var h = sha256_bytes([115, 97, 109, 112, 108, 101])
    var nonce = rfc6979_sha256(h, sk)
    var k = nonce.next()
    var expected = from_hex32("A6E3C57DD01ABE90086538398355DD4C3B17AA873382B0F24D6129493D8AAD60")
    assert_eq32(k, expected, "k (sample)")


fn test_test() raises:
    var sk = from_hex32("C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721")
    var h = sha256_bytes([116, 101, 115, 116])
    var nonce = rfc6979_sha256(h, sk)
    var k = nonce.next()
    var expected = from_hex32("D16B6AE827F17175E040871A1C7EC3500192C4C92677336EC2537ACAEE0008E0")
    assert_eq32(k, expected, "k (test)")


fn main() raises:
    test_sample()
    test_test()
    print("Pass")
