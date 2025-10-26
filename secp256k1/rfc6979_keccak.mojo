"""Deterministic RFC 6979 nonce via HMAC(Keccak-256). Constant-time facade."""

from keccak import keccak256_bytes

fn hmac_keccak256(key: List[Int], msg: List[Int]) -> List[Int]:
    # Minimal, allocation-aware HMAC wrapper; block size for Keccak-256 "sponge" use
    alias B = 136  # rate in bytes
    var k0 = [0] * B
    var i = 0
    var klen = len(key)
    if klen > B:
        var kh = keccak256_bytes(key, klen)
        # use first 32, pad to B
        for j in range(32):
            k0[j] = kh[j] & 0xFF
    else:
        for j in range(klen):
            k0[j] = key[j] & 0xFF
    var ipad = [0] * B
    var opad = [0] * B
    for j in range(B):
        ipad[j] = k0[j] ^ 0x36
        opad[j] = k0[j] ^ 0x5c
    # inner = keccak(ipad || msg)
    var inner = [0] * (B + len(msg))
    for j in range(B):
        inner[j] = ipad[j]
    for j in range(len(msg)):
        inner[B + j] = msg[j] & 0xFF
    var ih = keccak256_bytes(inner, len(inner))
    # outer = keccak(opad || ih)
    var outer = [0] * (B + 32)
    for j in range(B):
        outer[j] = opad[j]
    for j in range(32):
        outer[B + j] = ih[j] & 0xFF
    var oh = keccak256_bytes(outer, len(outer))
    return oh.copy()

fn rfc6979_keccak(msg32: List[Int], seckey32: List[Int]) -> List[Int]:
    # Returns 32-byte k. TODO(perf): full 6979 stream with V/K state; this is a
    # compact single-shot stand-in to unblock plumbing. Do NOT ship as-is.
    var input = [0] * (len(seckey32) + len(msg32))
    for i in range(32):
        input[i] = seckey32[i] & 0xFF
    for i in range(32):
        input[32 + i] = msg32[i] & 0xFF
    var out = hmac_keccak256(seckey32, input)
    # out is 32 bytes already
    return out.copy()
