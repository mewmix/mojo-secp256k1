from sys import argv
from python import Python
from secp256k1.verify import ecdsa_verify

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

fn hex_nibble(c: Int) -> Int:
    if 48 <= c <= 57:   return c - 48
    if 97 <= c <= 102:  return c - 87
    if 65 <= c <= 70:   return c - 55
    return 0

from secp256k1.utils import hex_to_bigint

fn main() raises:
    if len(argv()) != 2:
        print("Usage: mojo test_wycheproof_verify.mojo <input_file>")
        return

    var bn = Python.import_module("builtins")
    var file = bn.open(argv()[1], "r")

    while True:
        var line = file.readline()
        if not line:
            break

        var parts = line.strip().split('\t')
        if len(parts) != 4:
            continue

        var pub_key_hex = parts[0]
        var msg_hex = parts[1]
        var r_hex = parts[2]
        var s_hex = parts[3]

        var pub_key = hex_to_bytes(String(pub_key_hex))
        var msg = hex_to_bytes(String(msg_hex))
        var r = hex_to_bigint(String(r_hex))
        var s = hex_to_bigint(String(s_hex))

        try:
            if ecdsa_verify(pub_key, msg, r, s):
                print("valid")
            else:
                print("invalid")
        except:
            print("invalid")
