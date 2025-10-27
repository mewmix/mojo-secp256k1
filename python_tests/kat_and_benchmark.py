#!/usr/bin/env python3
"""Known Answer Test (KAT) and benchmark for ECDSA signing."""

import os
import time

try:
    from eth_keys import keys
    from eth_utils.crypto import keccak
except ImportError:
    print("Please install the eth-keys library: pip install eth-keys")
    exit(1)

PRIVATE_KEY_HEX = "c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721"
MESSAGE_BYTES = b"Ethereum deterministic nonce fixture"


def generate_kat_vector():
    """Generates an Ethereum-style signing vector using eth-keys."""
    private_key_bytes = bytes.fromhex(PRIVATE_KEY_HEX)
    message = MESSAGE_BYTES
    message_hash = keccak(message)

    private_key = keys.PrivateKey(private_key_bytes)
    signature = private_key.sign_msg_hash(message_hash)

    return {
        "private_key": private_key_bytes.hex(),
        "message": message.hex(),
        "message_hash": message_hash.hex(),
        "signature": signature.to_hex(),
        "public_key_uncompressed": private_key.public_key.to_bytes().hex(),
        "public_key_compressed": private_key.public_key.to_compressed_bytes().hex(),
        "r": signature.r.to_bytes(32, "big").hex(),
        "s": signature.s.to_bytes(32, "big").hex(),
        "v": signature.v,
    }

def benchmark_signing(iterations=1000):
    """Benchmarks the ECDSA signing process."""
    private_key = keys.PrivateKey(os.urandom(32))
    message_hash = keccak(b"benchmark message")
    
    start_time = time.time()
    for _ in range(iterations):
        private_key.sign_msg_hash(message_hash)
    end_time = time.time()
    
    total_time = end_time - start_time
    signs_per_second = iterations / total_time
    
    return {
        "iterations": iterations,
        "total_time": total_time,
        "signs_per_second": signs_per_second,
    }

if __name__ == "__main__":
    # Generate and print KAT vector
    kat_vector = generate_kat_vector()
    print("--- Known Answer Test (KAT) Vector ---")
    print(f"Private Key: {kat_vector['private_key']}")
    print(f"Message: {kat_vector['message']}")
    print(f"Message Hash: {kat_vector['message_hash']}")
    print(f"Signature (hex): {kat_vector['signature']}")
    print(f"Signature (r,s): {kat_vector['r']}{kat_vector['s']}")
    print(f"Recovery id (v): {kat_vector['v']}")


    # Run and print benchmark results
    print("\n--- ECDSA Signing Benchmark ---")
    benchmark_results = benchmark_signing()
    print(f"Iterations: {benchmark_results['iterations']}")
    print(f"Total Time: {benchmark_results['total_time']:.4f} seconds")
    print(f"Signatures per second: {benchmark_results['signs_per_second']:.2f}")
