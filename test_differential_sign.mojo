from python import Python
from sys import argv

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
    return out.copy()

fn to_hex32(b: List[Int]) -> String:
    var out = String("")
    var hexd = "0123456789abcdef"
    @parameter
    for i in range(32):
        var v = b[i] & 0xFF
        out += String(hexd[v >> 4]) + String(hexd[v & 0xF])
    return out

fn main() raises:
    if len(argv()) < 2:
        print("Usage: mojo test_differential_sign.mojo <input_file>")
        return

    var bn = Python.import_module("builtins")
    var file = bn.open(argv()[1], "r")

    # Print header
    print("sk_hex\tmsg_hex\tr_hex\ts_hex\tv")

    # Skip header
    _ = file.readline()

    while True:
        var line = file.readline()
        if not line:
            break

        var parts = line.strip().split('\t')
        var sk_hex = parts[0]
        var msg_hex = parts[1]

        var sk = hex_to_bytes(String(sk_hex))
        var msg = hex_to_bytes(String(msg_hex))
        var z = keccak256_bytes(msg, len(msg))
        var sig = ecdsa_sign_keccak(z, sk)

        print(
            String(sk_hex) + "\t" + String(msg_hex) + "\t" +
            to_hex32(sig.r) + "\t" + to_hex32(sig.s) +
            "\t" + String(sig.v)
        )
