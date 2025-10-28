#!/usr/bin/env python3
import os, sys, subprocess

MOJO_I = "-I . -I decimojo/src -I keccak"

# Core Mojo tests
MOJO_TESTS = [
    "test_secp256k1.mojo",          # Core scalar/point operations
    "test_secp256k1_kat.mojo",      # Known-answer tests
    "test_seckp256k1_rfc6979.mojo", # RFC6979 deterministic k generation
    "test_ecdsa_recover.mojo"       # Public key recovery
]

# Cross-verification with Python/eth-keys
VERIFY_TESTS = [
    # Generate signatures and verify with eth-keys
    ("test_sign_dump.mojo", "python_tests/verify_eth_keys.py"),
    # Generate recoverable signatures and verify recovery
    ("test_recover_dump.mojo", "python_tests/recover_and_compare.py"),
]

# Known-answer tests and benchmarks
EXTRA_TESTS = [
    "python_tests/kat_and_benchmark.py",
    "python_tests/verify_signatures.py",
]

CMDS = (
    # Run core Mojo tests
    [f"mojo {MOJO_I} {test}" for test in MOJO_TESTS] +
    # Run cross-verification tests
    [f'mojo {MOJO_I} {mojo} | .pixi/envs/default/bin/python {py}' 
     for mojo, py in VERIFY_TESTS] +
    # Run additional Python tests
    [f".pixi/envs/default/bin/python {test}" for test in EXTRA_TESTS]
)

def run(cmd):
    print(f"\n=== RUN: {cmd}\n", flush=True)
    ret = subprocess.call(cmd, shell=True, executable="/bin/bash")
    if ret != 0:
        print(f"FAILED: {cmd}", file=sys.stderr)
        sys.exit(ret)

if __name__ == "__main__":
    for c in CMDS:
        run(c)
    
    # Performance benchmarks are already included in kat_and_benchmark.py
    # so we don't need a separate benchmark run here.
    
    print("\nALL GREEN ✓")