#!/usr/bin/env python3
from eth_keys import keys
from eth_keys.datatypes import PrivateKey, Signature
from typing import Tuple

def verify_signature(msg_hash: bytes, signature: Tuple[bytes, bytes, int], pubkey: keys.PublicKey) -> bool:
    """Verify a secp256k1 signature using eth-keys."""
    try:
        r, s, v = signature
        # Create signature object from r, s, v components
        sig_obj = Signature(vrs=(v, int.from_bytes(r, 'big'), int.from_bytes(s, 'big')))
        return sig_obj.verify_msg_hash(msg_hash, pubkey)
    except Exception as e:
        print(f"Verification error: {e}")
        return False

def hex_to_bytes(hex_str: str) -> bytes:
    """Convert hex string to bytes, stripping '0x' if present."""
    if hex_str.startswith('0x'):
        hex_str = hex_str[2:]
    return bytes.fromhex(hex_str)

def init_verifier():
    """Initialize the verifier singleton - call once at start."""
    return True

def verify_test_vector(msg_hash: bytes, r: bytes, s: bytes, v: int, privkey: bytes) -> bool:
    """
    Verify a single test vector against reference implementation.
    Returns True if signature is valid.
    """
    try:
        # Create private key from bytes
        private_key = PrivateKey(privkey)
        public_key = private_key.public_key
        
        # Create signature object
        sig_obj = Signature(vrs=(
            v,
            int.from_bytes(r, 'big'),
            int.from_bytes(s, 'big')
        ))
        
        # Verify the signature
        return sig_obj.verify_msg_hash(msg_hash, public_key)
    except Exception as e:
        print(f"Test vector verification error: {e}")
        return False

# The interface that Mojo will use
def verify_mojo_signature(
    msg_hash_hex: str,
    r_hex: str,
    s_hex: str,
    v: int,
    privkey_hex: str
) -> bool:
    """
    Verify a signature produced by Mojo implementation.
    All inputs are hex strings (without 0x prefix) except v which is an integer.
    """
    try:
        msg_hash = hex_to_bytes(msg_hash_hex)
        r = hex_to_bytes(r_hex)
        s = hex_to_bytes(s_hex)
        privkey = hex_to_bytes(privkey_hex)
        
        return verify_test_vector(msg_hash, r, s, v, privkey)
    except Exception as e:
        print(f"Mojo signature verification error: {e}")
        return False