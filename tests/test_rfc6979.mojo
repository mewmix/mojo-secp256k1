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


from python import Python

fn main() raises:
    var json = Python.import_module("json")
    var f = Python.import_module("builtins").open("tests/rfc6979_p256.json")
    var tests = json.load(f)

    for test in tests:
        var sk_b64 = test['key']
        var msg_str = test['input']
        var expected_hex = test['output']

        # This is a bit of a hack to decode the base64 private key,
        # but it's the easiest way to do it for now.
        var base64 = Python.import_module("base64")
        var binascii = Python.import_module("binascii")
        var sk_der = base64.b64decode(sk_b64)

        # The private key is in DER format, so we need to extract the raw key.
        # This is another hack, but it works for these test vectors.
        var sk = List[Int]()
        for i in range(32):
            sk.append(Int(sk_der[36 + i]))

        var msg = List[Int]()
        for c in msg_str.codepoints():
            msg.append(Int(c))

        var h = sha256_bytes(msg)
        var nonce = rfc6979_sha256(h, sk)
        var k = nonce.next()

        var expected = from_hex32(String(expected_hex))
        assert_eq32(k, expected, "k")

    print("Pass")
