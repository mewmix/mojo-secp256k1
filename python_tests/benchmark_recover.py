#!/usr/bin/env python3
import sys, csv, io, binascii, time

from eth_keys.datatypes import Signature

def h2b(h: str) -> bytes:
    h = h[2:] if h.startswith(("0x","0X")) else h
    return binascii.unhexlify(h.encode())

def main():
    data = sys.stdin.read()
    # Find the header row and the data that follows
    header_index = data.find("msg32_hex")
    mojo_time_line = data[:header_index].strip().split('\n')[-1]
    csv_data = data[header_index:]

    rdr = csv.DictReader(io.StringIO(csv_data), delimiter="\t")

    rows = list(rdr)
    num_iterations = len(rows)

    start_time = time.time()
    for row in rows:
        msg32 = h2b(row["msg32_hex"])
        r = int(row["r_hex"], 16)
        s = int(row["s_hex"], 16)
        v = int(row["v"])

        sig = Signature(vrs=((v - 27) & 1, r, s))
        _ = sig.recover_public_key_from_msg_hash(msg32)
    end_time = time.time()

    duration = end_time - start_time

    print(mojo_time_line)
    print(f"Python recovery time ({num_iterations} iterations): {duration}s")

if __name__ == "__main__":
    main()
