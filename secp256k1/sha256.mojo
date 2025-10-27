from collections.inline_array import InlineArray


@always_inline
fn rotr(value: UInt32, amount: UInt32) -> UInt32:
    return (value >> amount) | (value << (32 - amount))


@always_inline
fn be_bytes_to_u32(b0: UInt8, b1: UInt8, b2: UInt8, b3: UInt8) -> UInt32:
    return (UInt32(b0) << 24) | (UInt32(b1) << 16) | (UInt32(b2) << 8) | UInt32(b3)

alias SHA256_K = InlineArray[UInt32, 64](
    UInt32(0x428A2F98), UInt32(0x71374491), UInt32(0xB5C0FBCF), UInt32(0xE9B5DBA5),
    UInt32(0x3956C25B), UInt32(0x59F111F1), UInt32(0x923F82A4), UInt32(0xAB1C5ED5),
    UInt32(0xD807AA98), UInt32(0x12835B01), UInt32(0x243185BE), UInt32(0x550C7DC3),
    UInt32(0x72BE5D74), UInt32(0x80DEB1FE), UInt32(0x9BDC06A7), UInt32(0xC19BF174),
    UInt32(0xE49B69C1), UInt32(0xEFBE4786), UInt32(0x0FC19DC6), UInt32(0x240CA1CC),
    UInt32(0x2DE92C6F), UInt32(0x4A7484AA), UInt32(0x5CB0A9DC), UInt32(0x76F988DA),
    UInt32(0x983E5152), UInt32(0xA831C66D), UInt32(0xB00327C8), UInt32(0xBF597FC7),
    UInt32(0xC6E00BF3), UInt32(0xD5A79147), UInt32(0x06CA6351), UInt32(0x14292967),
    UInt32(0x27B70A85), UInt32(0x2E1B2138), UInt32(0x4D2C6DFC), UInt32(0x53380D13),
    UInt32(0x650A7354), UInt32(0x766A0ABB), UInt32(0x81C2C92E), UInt32(0x92722C85),
    UInt32(0xA2BFE8A1), UInt32(0xA81A664B), UInt32(0xC24B8B70), UInt32(0xC76C51A3),
    UInt32(0xD192E819), UInt32(0xD6990624), UInt32(0xF40E3585), UInt32(0x106AA070),
    UInt32(0x19A4C116), UInt32(0x1E376C08), UInt32(0x2748774C), UInt32(0x34B0BCB5),
    UInt32(0x391C0CB3), UInt32(0x4ED8AA4A), UInt32(0x5B9CCA4F), UInt32(0x682E6FF3),
    UInt32(0x748F82EE), UInt32(0x78A5636F), UInt32(0x84C87814), UInt32(0x8CC70208),
    UInt32(0x90BEFFFA), UInt32(0xA4506CEB), UInt32(0xBEF9A3F7), UInt32(0xC67178F2)
)


fn sha256_bytes(data: List[Int]) -> List[Int]:
    var message = List[UInt8]()
    for byte in data:
        message.append(UInt8(byte & 0xFF))

    var original_bit_len = UInt64(len(message)) * 8
    message.append(UInt8(0x80))
    while (len(message) + 8) % 64 != 0:
        message.append(UInt8(0))

    var length_bytes = [
        UInt8((original_bit_len >> 56) & 0xFF),
        UInt8((original_bit_len >> 48) & 0xFF),
        UInt8((original_bit_len >> 40) & 0xFF),
        UInt8((original_bit_len >> 32) & 0xFF),
        UInt8((original_bit_len >> 24) & 0xFF),
        UInt8((original_bit_len >> 16) & 0xFF),
        UInt8((original_bit_len >> 8) & 0xFF),
        UInt8(original_bit_len & 0xFF),
    ]
    for byte in length_bytes:
        message.append(byte)

    var h0 = UInt32(0x6A09E667)
    var h1 = UInt32(0xBB67AE85)
    var h2 = UInt32(0x3C6EF372)
    var h3 = UInt32(0xA54FF53A)
    var h4 = UInt32(0x510E527F)
    var h5 = UInt32(0x9B05688C)
    var h6 = UInt32(0x1F83D9AB)
    var h7 = UInt32(0x5BE0CD19)

    var chunk_count = len(message) // 64
    for chunk_index in range(chunk_count):
        var chunk_base = chunk_index * 64
        var w = List[UInt32]()
        for _ in range(64):
            w.append(UInt32(0))

        @parameter
        for i in range(16):
            var offset = chunk_base + i * 4
            w[i] = be_bytes_to_u32(
                message[offset],
                message[offset + 1],
                message[offset + 2],
                message[offset + 3],
            )

        @parameter
        for i in range(16, 64):
            var s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3)
            var s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10)
            w[i] = w[i - 16] + s0 + w[i - 7] + s1

        var a = h0
        var b = h1
        var c = h2
        var d = h3
        var e = h4
        var f = h5
        var g = h6
        var h = h7

        @parameter
        for i in range(64):
            var S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)
            var ch = (e & f) ^ ((~e) & g)
            var temp1 = h + S1 + ch + SHA256_K[i] + w[i]
            var S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)
            var maj = (a & b) ^ (a & c) ^ (b & c)
            var temp2 = S0 + maj

            h = g
            g = f
            f = e
            e = d + temp1
            d = c
            c = b
            b = a
            a = temp1 + temp2

        h0 = h0 + a
        h1 = h1 + b
        h2 = h2 + c
        h3 = h3 + d
        h4 = h4 + e
        h5 = h5 + f
        h6 = h6 + g
        h7 = h7 + h

    var digest = [0] * 32
    var words = [
        h0, h1, h2, h3,
        h4, h5, h6, h7,
    ]
    var out_index = 0
    for word in words:
        digest[out_index] = Int((word >> 24) & 0xFF)
        digest[out_index + 1] = Int((word >> 16) & 0xFF)
        digest[out_index + 2] = Int((word >> 8) & 0xFF)
        digest[out_index + 3] = Int(word & 0xFF)
        out_index += 4
    return digest.copy()
