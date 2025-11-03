from time import perf_counter_ns
from python import Python
from keccak.keccak import keccak256_bytes
from secp256k1.sign import ecdsa_sign_keccak
from secp256k1.recover import ecdsa_recover_keccak

fn to_bytes(msg: String) -> List[Int]:
    var out = [0] * len(msg)
    var idx = 0
    for cp in msg.codepoints():
        out[idx] = Int(cp) & 0xFF
        idx += 1
    return out^

fn get_iterations(default_iters: Int) raises -> Int:
    var os = Python.import_module("os")
    var env = os.environ
    var raw = env.get("MOJO_BENCH_ITERATIONS")
    if raw is None:
        return default_iters
    try:
        var value = Int(Python.int(raw))
        if value > 0:
            return value
    except:
        pass
    return default_iters

fn main() raises:
    var iterations = get_iterations(50)

    var message = to_bytes("benchmark message")
    var msg32 = keccak256_bytes(message, len(message))
    var seckey = [
        0x4c, 0x08, 0x83, 0xa6, 0x91, 0x02, 0x93, 0x7d,
        0x62, 0x31, 0x47, 0x1b, 0x5d, 0xbb, 0x62, 0x04,
        0xfe, 0x51, 0x29, 0x61, 0x70, 0x82, 0x79, 0xe3,
        0xf6, 0xc7, 0xb1, 0xe3, 0xd5, 0xf8, 0xe7, 0xf8,
    ]

    var sig = ecdsa_sign_keccak(msg32, seckey)
    _ = ecdsa_recover_keccak(msg32, sig.r, sig.s, sig.v)

    var start = perf_counter_ns()
    var i = 0
    while i < iterations:
        sig = ecdsa_sign_keccak(msg32, seckey)
        i += 1
    var sign_total = perf_counter_ns() - start
    var sign_avg = Float64(sign_total) / Float64(iterations)
    var sign_per_sec = 1_000_000_000.0 / sign_avg

    var v = sig.v
    var r_bytes = sig.r.copy()
    var s_bytes = sig.s.copy()

    start = perf_counter_ns()
    i = 0
    while i < iterations:
        _ = ecdsa_recover_keccak(msg32, r_bytes, s_bytes, v)
        i += 1
    var recover_total = perf_counter_ns() - start
    var recover_avg = Float64(recover_total) / Float64(iterations)
    var recover_per_sec = 1_000_000_000.0 / recover_avg

    print("mojo.iterations=" + String(iterations))
    print("mojo.sign_ns_per_iter=" + String(sign_avg))
    print("mojo.sign_ops_per_sec=" + String(sign_per_sec))
    print("mojo.recover_ns_per_iter=" + String(recover_avg))
    print("mojo.recover_ops_per_sec=" + String(recover_per_sec))
