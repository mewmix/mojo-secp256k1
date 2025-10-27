#!/usr/bin/env python3
import sys, csv, io, binascii
from eth_keys.datatypes import Signature
from eth_keys import keys

def h2b(h: str) -> bytes:
    h = h[2:] if h.startswith(("0x","0X")) else h
    return binascii.unhexlify(h.encode())

def v_to_01(v: int) -> int:
    # Mojo emits {27..30}; eth-keys wants 0/1 parity here
    return (v - 27) & 1 if v >= 27 else (v & 1)

def main():
    data = sys.stdin.read()
    rdr = csv.DictReader(io.StringIO(data), delimiter="\t")
    fails, total = [], 0
    for row in rdr:
        total += 1
        msg32 = h2b(row["msg32_hex"])
        r = int(row["r_hex"], 16)
        s = int(row["s_hex"], 16)
        v01 = v_to_01(int(row["v"]))
        sig = Signature(vrs=(v01, r, s))

        rec_pub = sig.recover_public_key_from_msg_hash(msg32)
        rec_hex = rec_pub.to_bytes().hex()     # 64 bytes (x||y)
        mojo_pub_hex = row["pub_xy_hex"].lower()

        ok = (rec_hex == mojo_pub_hex)
        if not ok:
            fails.append({
                "idx": row["idx"],
                "rec": rec_hex,
                "mojo": mojo_pub_hex,
                "r": row["r_hex"], "s": row["s_hex"], "v": row["v"],
                "msg32": row["msg32_hex"]
            })
    if fails:
        print(f"FAILURES DETECTED: {len(fails)}", file=sys.stderr)
        for f in fails:
            print(f"idx={f['idx']} mismatch", file=sys.stderr)
            print(f"  rec_pub={f['rec']}", file=sys.stderr)
            print(f"  mojo_pub={f['mojo']}", file=sys.stderr)
            print(f"  r={f['r']} s={f['s']} v={f['v']} msg32={f['msg32']}", file=sys.stderr)
        sys.exit(1)
    print(f"PASS: {total} recoveries matched Mojo pubkeys")
    sys.exit(0)

if __name__ == "__main__":
    main()
