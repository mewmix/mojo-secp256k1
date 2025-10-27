from secp256k1.sign import ecdsa_sign_keccak
from keccak.keccak import keccak256_bytes

fn hex_nibble(c: Int) -> Int:
    if 48 <= c <= 57:   return c - 48
    if 97 <= c <= 102:  return c - 87
    if 65 <= c <= 70:   return c - 55
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
    return out.copy()           # <<< key fix

fn to_hex32(b: List[Int]) -> String:
    var out = String("")
    var hexd = "0123456789abcdef"
    @parameter
    for i in range(32):
        var v = b[i] & 0xFF
        out += String(hexd[v >> 4]) + String(hexd[v & 0xF])
    return out

fn to_hex(bs: List[Int]) -> String:
    var out = String("")
    var hexd = "0123456789abcdef"
    for v in bs:
        var x = v & 0xFF
        out += String(hexd[x >> 4]) + String(hexd[x & 0xF])
    return out

fn main() raises:
    var sk_hex = [
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        "4c0883a69102937d6231471b5dbb6204fe512961708279e3f6c7b1e3d5f8e7f8",
    ]
    var msgs = [
        [0x41,0x42,0x43],                # "ABC"
        [0x73,0x61,0x6d,0x70,0x6c,0x65], # "sample"
        [0x74,0x65,0x73,0x74],           # "test"
    ]

    var idx = 0
    print("idx\tsk_hex\tmsg_hex\tmsg32_hex\tr_hex\ts_hex\tv")
    for skh in sk_hex:
        var sk = hex_to_bytes(skh)
        for msg in msgs:
            var z = keccak256_bytes(msg, len(msg))
            var sig = ecdsa_sign_keccak(z, sk)
            print(
                String(idx) + "\t" + skh + "\t" + to_hex(msg) + "\t" +
                to_hex32(z) + "\t" + to_hex32(sig.r) + "\t" + to_hex32(sig.s) +
                "\t" + String(sig.v)
            )
            idx += 1