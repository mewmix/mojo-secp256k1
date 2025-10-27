from secp256k1.sign import ecdsa_sign_keccak, ecdsa_recover, pubkey_from_seckey, SigCompact
from keccak.keccak import keccak256_bytes
from time import perf_counter_ns

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

fn to_hex32(b: List[Int]) -> String:
    var out = String("")
    var hexd = "0123456789abcdef"
    @parameter
    for i in range(32):
        var v = b[i] & 0xFF
        out += String(hexd[v >> 4]) + String(hexd[v & 0xF])
    return out

fn main() raises:
    var num_iterations = 100
    var sk_hex = "0x0000000000000000000000000000000000000000000000000000000000000001"
    var sk = hex_to_bytes(sk_hex)

    var msg_hashes = List[List[Int]]()
    var signatures = List[SigCompact]()

    for i in range(num_iterations):
        var msg = [0x41, 0x42, 0x43, i] # "ABC" + i
        var z = keccak256_bytes(msg, len(msg))
        var sig = ecdsa_sign_keccak(z, sk)
        msg_hashes.append(z.copy())
        signatures.append(sig.copy())

    var start_time = perf_counter_ns()
    for i in range(num_iterations):
        _ = ecdsa_recover(msg_hashes[i], signatures[i])
    var end_time = perf_counter_ns()

    var duration = (end_time - start_time) / 1e9
    print("Mojo recovery time (" + String(num_iterations) + " iterations): " + String(duration) + "s")

    print("msg32_hex\tr_hex\ts_hex\tv")
    for i in range(num_iterations):
        print(
            to_hex32(msg_hashes[i]) + "\t" + to_hex32(signatures[i].r) + "\t" +
            to_hex32(signatures[i].s) + "\t" + String(signatures[i].v)
        )
