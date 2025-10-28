#!/usr/bin/env python3
import os
import sys
import csv
import io
import subprocess
import binascii
import tempfile
from coincurve.keys import PrivateKey, PublicKey
from eth_hash.auto import keccak
from ecdsa.util import sigencode_der

def run_mojo_signer(keys_and_messages):
    """
    Runs the Mojo signing script and returns the output.
    """
    # Use the full path to the python executable to avoid issues
    python_executable = ".pixi/envs/default/bin/python"

<<<<<<< HEAD
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_file:
        writer = csv.writer(temp_file, delimiter='\t')
        writer.writerow(["sk_hex", "msg_hex"])
        for sk, msg in keys_and_messages:
            writer.writerow([sk.hex(), msg.hex()])
        temp_file_path = temp_file.name

    # Run the Mojo script
    mojo_cmd = (
        f"mojo -I . -I decimojo/src -I keccak "
<<<<<<< HEAD
        f"tests/test_differential_sign.mojo {temp_file_path}"
    )
    process = subprocess.Popen(
        mojo_cmd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        executable="/bin/bash"
    )
    stdout, stderr = process.communicate()

    if process.returncode != 0:
        print("Mojo script failed:", file=sys.stderr)
        print(stderr.decode(), file=sys.stderr)
        sys.exit(1)

    return stdout.decode()

def main():
    # Generate 10000 random keys and messages
    keys_and_messages = []
    for _ in range(10000):
        sk = os.urandom(32)
        msg = os.urandom(32)
        keys_and_messages.append((sk, msg))

    # Run the Mojo signer
    mojo_output = run_mojo_signer(keys_and_messages)

    # Process the output from the Mojo script
    reader = csv.DictReader(io.StringIO(mojo_output), delimiter='\t')
    fails = 0
    total = 0
    for row in reader:
        if not row or row.get("v") is None:
            continue
        total += 1
        sk_hex = row["sk_hex"]
        msg_hex = row["msg_hex"]
        r_hex = row["r_hex"]
        s_hex = row["s_hex"]
        v = int(row["v"])

        sk = binascii.unhexlify(sk_hex)
        msg = binascii.unhexlify(msg_hex)
        msg_hash = keccak(msg)

        priv = PrivateKey(sk)
        pub = priv.public_key

        # Verify the signature
        r = int(r_hex, 16)
        s = int(s_hex, 16)
        signature = sigencode_der(r, s, 32 * 8)
        if not pub.verify(signature, msg_hash, hasher=None):
            print(f"Signature verification failed for sk: {sk_hex}", file=sys.stderr)
            fails += 1
            continue

        # Recover the public key
        rec_id = v - 27
        rec_sig = binascii.unhexlify(r_hex + s_hex) + bytes([rec_id])
        rec_pub = PublicKey.from_signature_and_message(rec_sig, msg_hash, hasher=None)

        if pub.format(compressed=False) != rec_pub.format(compressed=False):
            print(f"Public key recovery failed for sk: {sk_hex}", file=sys.stderr)
            fails += 1

    if fails > 0:
        print(f"FAIL: {fails} of {total} tests failed.", file=sys.stderr)
        sys.exit(1)

    print(f"PASS: All {total} signatures verified and public keys recovered successfully.")

if __name__ == "__main__":
    main()
