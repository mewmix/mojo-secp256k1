#!/usr/bin/env python3
import sys, csv, io, binascii
from eth_keys.datatypes import PrivateKey, Signature
from rlp import encode
from rlp.sedes import big_endian_int, binary
from eth_hash.auto import keccak

def h2b(h: str) -> bytes:
    h = h[2:] if h.startswith(("0x","0X")) else h
    return binascii.unhexlify(h.encode())

def verify_row(row):
    sk = h2b(row["sk_hex"])
    msg32 = h2b(row["msg32_hex"])
    r = int(row["r_hex"], 16)
    s = int(row["s_hex"], 16)
    v = int(row["v"])
    chain_id = 1

    # Convert EIP-155 v to recovery id
    v_recovery = (v - 35) % 2

    # Verify the signature
    priv = PrivateKey(sk)
    pub = priv.public_key
    sig = Signature(vrs=(v_recovery, r, s))
    if not sig.verify_msg_hash(msg32, pub):
        return False

    # Verify the signed transaction RLP
    nonce = 0
    gas_price = 20000000000
    gas_limit = 21000
    to = h2b("0x7f5c7c5abC18ACF65DBFAD8bB9fF487f47fF83e4")
    value = 1000000000000000000
    data = b''

    unsigned_tx = [nonce, gas_price, gas_limit, to, value, data, chain_id, 0, 0]
    expected_msg32 = keccak(encode(unsigned_tx))
    if msg32 != expected_msg32:
        return False

    signed_tx = [nonce, gas_price, gas_limit, to, value, data, v, r, s]
    expected_signed_tx_rlp = encode(signed_tx)

    return h2b(row["signed_tx_hex"]) == expected_signed_tx_rlp

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
            print(f"  signed_tx_hex={r['signed_tx_hex']}", file=sys.stderr)
        sys.exit(1)
    print(f"PASS: {total} legacy signatures verified against eth-keys")
    sys.exit(0)

if __name__ == "__main__":
    main()
