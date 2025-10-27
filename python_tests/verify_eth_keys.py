#!/usr/bin/env python3
import sys, csv, io, binascii
from eth_keys.datatypes import PrivateKey, Signature

def h2b(h: str) -> bytes:
    h = h[2:] if h.startswith(("0x","0X")) else h
    return binascii.unhexlify(h.encode())

def v_to_01(v: int) -> int:
    # Mojo outputs v in {27..30}; keep only parity bit
    return (v - 27) & 1 if v >= 27 else (v & 1)

def verify_row(row):
    sk = h2b(row["sk_hex"])
    msg32 = h2b(row["msg32_hex"])
    r = int(row["r_hex"], 16)
    s = int(row["s_hex"], 16)
    v01 = v_to_01(int(row["v"]))

    priv = PrivateKey(sk)
    pub = priv.public_key
    sig = Signature(vrs=(v01, r, s))
    return sig.verify_msg_hash(msg32, pub)

def main():
    data = sys.stdin.read()
    rdr = csv.DictReader(io.StringIO(data), delimiter="\t")
    fails, total = [], 0
    for row in rdr:
        total += 1
        if not verify_row(row):
            fails.append(row)
    if fails:
        print(f"FAILURES DETECTED: {len(fails)}", file=sys.stderr)
        for r in fails:
            print(f"idx={r['idx']} sk={r['sk_hex']} msg32={r['msg32_hex']}", file=sys.stderr)
            print(f"  r={r['r_hex']} s={r['s_hex']} v={r['v']}", file=sys.stderr)
        sys.exit(1)
    print(f"PASS: {total} signatures verified against eth-keys")
    sys.exit(0)

if __name__ == "__main__":
    main()