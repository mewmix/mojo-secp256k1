#!/usr/bin/env python3
import json
import os
import sys
import subprocess
import binascii
import csv
import tempfile
from ecdsa import SECP256k1
from ecdsa.util import sigdecode_der

def run_mojo_verifier_batch(batch):
    """
    Runs the Mojo verification script for a batch of tests and returns the output.
    """
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_file:
        writer = csv.writer(temp_file, delimiter='\t')
        for pub_key, msg, r, s in batch:
            writer.writerow([pub_key.hex(), msg.hex(), hex(r)[2:], hex(s)[2:]])
        temp_file_path = temp_file.name

    mojo_cmd = (
        f"mojo -I . -I decimojo/src -I keccak "
        f"tests/test_wycheproof_verify.mojo {temp_file_path}"
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
        return ["fail"] * len(batch)

    return stdout.decode().strip().split('\n')

def main():
    with open("external/wycheproof/testvectors_v1/ecdsa_secp256k1_sha256_test.json") as f:
        data = json.load(f)

    fails = 0
    total = 0
    batch = []
    batch_size = 100

    for test_group in data["testGroups"]:
        pub_key = binascii.unhexlify(test_group["publicKey"]["uncompressed"])
        for test in test_group["tests"]:
            total += 1
            msg = binascii.unhexlify(test["msg"])
            sig = binascii.unhexlify(test["sig"])
            try:
                r, s = sigdecode_der(sig, SECP256k1.order)
            except:
                r, s = 0, 0 # Invalid signature

            batch.append((pub_key, msg, r, s, test["tcId"], test["result"]))

            if len(batch) >= batch_size:
                results = run_mojo_verifier_batch([(b[0], b[1], b[2], b[3]) for b in batch])
                for i, actual in enumerate(results):
                    tcId = batch[i][4]
                    expected = batch[i][5]
                    if actual != expected:
                        if expected == "acceptable" and actual == "valid":
                            pass
                        else:
                            print(f"FAIL: tcId={str(tcId)}, expected={expected}, actual={actual}", file=sys.stderr)
                            fails += 1
                batch = []

    if batch:
        results = run_mojo_verifier_batch([(b[0], b[1], b[2], b[3]) for b in batch])
        for i, actual in enumerate(results):
            tcId = batch[i][4]
            expected = batch[i][5]
            if actual != expected:
                if expected == "acceptable" and actual == "valid":
                    pass
                else:
                    print(f"FAIL: tcId={str(tcId)}, expected={expected}, actual={actual}", file=sys.stderr)
                    fails += 1

    if fails > 0:
        print(f"FAIL: {fails} of {total} Wycheproof tests failed.", file=sys.stderr)
        sys.exit(1)

    print(f"PASS: All {total} Wycheproof tests passed.")

if __name__ == "__main__":
    main()
