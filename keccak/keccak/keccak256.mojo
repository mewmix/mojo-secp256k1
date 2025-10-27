from collections.inline_array import InlineArray

alias RATE = 136
alias LANES = 17  # RATE / 8
alias ROUNDS = 24
alias USE_UNROLLED_THETA_CHI = True

alias RC = InlineArray[UInt64, 24](
    UInt64(0x0000000000000001), UInt64(0x0000000000008082),
    UInt64(0x800000000000808A), UInt64(0x8000000080008000),
    UInt64(0x000000000000808B), UInt64(0x0000000080000001),
    UInt64(0x8000000080008081), UInt64(0x8000000000008009),
    UInt64(0x000000000000008A), UInt64(0x0000000000000088),
    UInt64(0x0000000080008009), UInt64(0x000000008000000A),
    UInt64(0x000000008000808B), UInt64(0x800000000000008B),
    UInt64(0x8000000000008089), UInt64(0x8000000000008003),
    UInt64(0x8000000000008002), UInt64(0x8000000000000080),
    UInt64(0x000000000000800A), UInt64(0x800000008000000A),
    UInt64(0x8000000080008081), UInt64(0x8000000000008080),
    UInt64(0x0000000080000001), UInt64(0x8000000080008008),
)

alias RHO = InlineArray[InlineArray[Int, 5], 5](
    InlineArray[Int, 5](0, 36, 3, 41, 18),
    InlineArray[Int, 5](1, 44, 10, 45, 2),
    InlineArray[Int, 5](62, 6, 43, 15, 61),
    InlineArray[Int, 5](28, 55, 25, 21, 56),
    InlineArray[Int, 5](27, 20, 39, 8, 14),
)



fn to_hex32(d: List[Int]) -> String:
    var lut = "0123456789abcdef"
    var out = ""
    for v in d:
        var b = v & 0xFF
        out += lut[(b >> 4) & 0xF]
        out += lut[b & 0xF]
    return out

@always_inline
fn rotl64(x: UInt64, n: Int) -> UInt64:
    if n == 0:
        return x
    var shift = UInt64(n)
    var inv = UInt64(64 - n)
    return (x << shift) | (x >> inv)


@always_inline
fn xor_state_block(lane_ptrs: InlineArray[UnsafePointer[UInt64], LANES], lanes: UnsafePointer[UInt64]) -> None:
    @parameter
    for idx in range(LANES):
        lane_ptrs[idx][] = lane_ptrs[idx][] ^ lanes.offset(idx)[]



fn keccak_f1600(state_ptr: UnsafePointer[UInt64]) -> None:

    @parameter
    if USE_UNROLLED_THETA_CHI:
        var Aba = state_ptr[]
        var Abe = state_ptr.offset(1)[]
        var Abi = state_ptr.offset(2)[]
        var Abo = state_ptr.offset(3)[]
        var Abu = state_ptr.offset(4)[]
        var Aga = state_ptr.offset(5)[]
        var Age = state_ptr.offset(6)[]
        var Agi = state_ptr.offset(7)[]
        var Ago = state_ptr.offset(8)[]
        var Agu = state_ptr.offset(9)[]
        var Aka = state_ptr.offset(10)[]
        var Ake = state_ptr.offset(11)[]
        var Aki = state_ptr.offset(12)[]
        var Ako = state_ptr.offset(13)[]
        var Aku = state_ptr.offset(14)[]
        var Ama = state_ptr.offset(15)[]
        var Ame = state_ptr.offset(16)[]
        var Ami = state_ptr.offset(17)[]
        var Amo = state_ptr.offset(18)[]
        var Amu = state_ptr.offset(19)[]
        var Asa = state_ptr.offset(20)[]
        var Ase = state_ptr.offset(21)[]
        var Asi = state_ptr.offset(22)[]
        var Aso = state_ptr.offset(23)[]
        var Asu = state_ptr.offset(24)[]

        @parameter
        for round in range(ROUNDS):
            var C0 = Aba ^ Aga ^ Aka ^ Ama ^ Asa
            var C1 = Abe ^ Age ^ Ake ^ Ame ^ Ase
            var C2 = Abi ^ Agi ^ Aki ^ Ami ^ Asi
            var C3 = Abo ^ Ago ^ Ako ^ Amo ^ Aso
            var C4 = Abu ^ Agu ^ Aku ^ Amu ^ Asu

            var D0 = C4 ^ rotl64(C1, 1)
            var D1 = C0 ^ rotl64(C2, 1)
            var D2 = C1 ^ rotl64(C3, 1)
            var D3 = C2 ^ rotl64(C4, 1)
            var D4 = C3 ^ rotl64(C0, 1)

            Aba = Aba ^ D0
            Abe = Abe ^ D1
            Abi = Abi ^ D2
            Abo = Abo ^ D3
            Abu = Abu ^ D4
            Aga = Aga ^ D0
            Age = Age ^ D1
            Agi = Agi ^ D2
            Ago = Ago ^ D3
            Agu = Agu ^ D4
            Aka = Aka ^ D0
            Ake = Ake ^ D1
            Aki = Aki ^ D2
            Ako = Ako ^ D3
            Aku = Aku ^ D4
            Ama = Ama ^ D0
            Ame = Ame ^ D1
            Ami = Ami ^ D2
            Amo = Amo ^ D3
            Amu = Amu ^ D4
            Asa = Asa ^ D0
            Ase = Ase ^ D1
            Asi = Asi ^ D2
            Aso = Aso ^ D3
            Asu = Asu ^ D4

            var B0 = Aba
            var B1 = rotl64(Age, 44)
            var B2 = rotl64(Aki, 43)
            var B3 = rotl64(Amo, 21)
            var B4 = rotl64(Asu, 14)
            var B5 = rotl64(Abo, 28)
            var B6 = rotl64(Agu, 20)
            var B7 = rotl64(Aka, 3)
            var B8 = rotl64(Ame, 45)
            var B9 = rotl64(Asi, 61)
            var B10 = rotl64(Abe, 1)
            var B11 = rotl64(Agi, 6)
            var B12 = rotl64(Ako, 25)
            var B13 = rotl64(Amu, 8)
            var B14 = rotl64(Asa, 18)
            var B15 = rotl64(Abu, 27)
            var B16 = rotl64(Aga, 36)
            var B17 = rotl64(Ake, 10)
            var B18 = rotl64(Ami, 15)
            var B19 = rotl64(Aso, 56)
            var B20 = rotl64(Abi, 62)
            var B21 = rotl64(Ago, 55)
            var B22 = rotl64(Aku, 39)
            var B23 = rotl64(Ama, 41)
            var B24 = rotl64(Ase, 2)

            Aba = B0 ^ ((~B1) & B2)
            Abe = B1 ^ ((~B2) & B3)
            Abi = B2 ^ ((~B3) & B4)
            Abo = B3 ^ ((~B4) & B0)
            Abu = B4 ^ ((~B0) & B1)

            Aga = B5 ^ ((~B6) & B7)
            Age = B6 ^ ((~B7) & B8)
            Agi = B7 ^ ((~B8) & B9)
            Ago = B8 ^ ((~B9) & B5)
            Agu = B9 ^ ((~B5) & B6)

            Aka = B10 ^ ((~B11) & B12)
            Ake = B11 ^ ((~B12) & B13)
            Aki = B12 ^ ((~B13) & B14)
            Ako = B13 ^ ((~B14) & B10)
            Aku = B14 ^ ((~B10) & B11)

            Ama = B15 ^ ((~B16) & B17)
            Ame = B16 ^ ((~B17) & B18)
            Ami = B17 ^ ((~B18) & B19)
            Amo = B18 ^ ((~B19) & B15)
            Amu = B19 ^ ((~B15) & B16)

            Asa = B20 ^ ((~B21) & B22)
            Ase = B21 ^ ((~B22) & B23)
            Asi = B22 ^ ((~B23) & B24)
            Aso = B23 ^ ((~B24) & B20)
            Asu = B24 ^ ((~B20) & B21)

            Aba = Aba ^ RC[round]

        state_ptr[] = Aba
        state_ptr.offset(1)[] = Abe
        state_ptr.offset(2)[] = Abi
        state_ptr.offset(3)[] = Abo
        state_ptr.offset(4)[] = Abu
        state_ptr.offset(5)[] = Aga
        state_ptr.offset(6)[] = Age
        state_ptr.offset(7)[] = Agi
        state_ptr.offset(8)[] = Ago
        state_ptr.offset(9)[] = Agu
        state_ptr.offset(10)[] = Aka
        state_ptr.offset(11)[] = Ake
        state_ptr.offset(12)[] = Aki
        state_ptr.offset(13)[] = Ako
        state_ptr.offset(14)[] = Aku
        state_ptr.offset(15)[] = Ama
        state_ptr.offset(16)[] = Ame
        state_ptr.offset(17)[] = Ami
        state_ptr.offset(18)[] = Amo
        state_ptr.offset(19)[] = Amu
        state_ptr.offset(20)[] = Asa
        state_ptr.offset(21)[] = Ase
        state_ptr.offset(22)[] = Asi
        state_ptr.offset(23)[] = Aso
        state_ptr.offset(24)[] = Asu
    else:
        var C = [UInt64(0)] * 5
        var D = [UInt64(0)] * 5
        var B = InlineArray[UInt64, 25](fill=0)

        for round in range(ROUNDS):
            for x in range(5):
                C[x] = state_ptr.offset(x)[] ^ state_ptr.offset(x + 5)[] ^ state_ptr.offset(x + 10)[] ^ state_ptr.offset(x + 15)[] ^ state_ptr.offset(x + 20)[]
            for x in range(5):
                D[x] = C[(x + 4) % 5] ^ rotl64(C[(x + 1) % 5], 1)
            for i in range(25):
                var lane_idx = i % 5
                state_ptr.offset(i)[] = state_ptr.offset(i)[] ^ D[lane_idx]

            for x in range(5):
                for y in range(5):
                    var idx = x + 5 * y
                    var new_idx = y + 5 * ((2 * x + 3 * y) % 5)
                    B[new_idx] = rotl64(state_ptr.offset(idx)[], RHO[x][y])

            for y in range(0, 25, 5):
                var b0 = B[y + 0]
                var b1 = B[y + 1]
                var b2 = B[y + 2]
                var b3 = B[y + 3]
                var b4 = B[y + 4]
                state_ptr.offset(y + 0)[] = b0 ^ ((~b1) & b2)
                state_ptr.offset(y + 1)[] = b1 ^ ((~b2) & b3)
                state_ptr.offset(y + 2)[] = b2 ^ ((~b3) & b4)
                state_ptr.offset(y + 3)[] = b3 ^ ((~b4) & b0)
                state_ptr.offset(y + 4)[] = b4 ^ ((~b0) & b1)

            state_ptr[] = state_ptr[] ^ RC[round]


fn keccak256_raw(ptr: UnsafePointer[UInt8], length: Int) -> List[Int]:
    var state = InlineArray[UInt64, 25](fill=0)
    var state_ptr = UnsafePointer(to=state[0])
    var state_bytes = state_ptr.bitcast[UInt8]()
    var lane_ptrs = InlineArray[UnsafePointer[UInt64], LANES](
        state_ptr,
        state_ptr.offset(1),
        state_ptr.offset(2),
        state_ptr.offset(3),
        state_ptr.offset(4),
        state_ptr.offset(5),
        state_ptr.offset(6),
        state_ptr.offset(7),
        state_ptr.offset(8),
        state_ptr.offset(9),
        state_ptr.offset(10),
        state_ptr.offset(11),
        state_ptr.offset(12),
        state_ptr.offset(13),
        state_ptr.offset(14),
        state_ptr.offset(15),
        state_ptr.offset(16),
    )
    var processed = 0
    var zero_stub = InlineArray[UInt8, 1](fill=UInt8(0))
    var cursor: UnsafePointer[UInt8]
    if length > 0:
        cursor = ptr
    else:
        cursor = UnsafePointer(to=zero_stub[0])

    while processed + RATE <= length:
        xor_state_block(lane_ptrs, cursor.bitcast[UInt64]())
        keccak_f1600(state_ptr)
        cursor = cursor.offset(RATE)
        processed += RATE

    var rem = length - processed
    for i in range(rem):
        state_bytes.offset(i)[] = state_bytes.offset(i)[] ^ (cursor + i)[]
    state_bytes.offset(rem)[] = state_bytes.offset(rem)[] ^ UInt8(0x01)
    state_bytes.offset(RATE - 1)[] = state_bytes.offset(RATE - 1)[] ^ UInt8(0x80)

    keccak_f1600(state_ptr)

    var out = [0] * 32
    for i in range(32):
        out[i] = Int(state_bytes.offset(i)[])
    return out.copy()


fn keccak256_bytes_from_u8(data: List[UInt8], length: Int) -> List[Int]:
    if length == 0:
        var stub = [UInt8(0)] * 1
        return keccak256_raw(UnsafePointer(to=stub[0]), 0)
    var ptr = UnsafePointer(to=data[0])
    return keccak256_raw(ptr, length)


fn keccak256_bytes(data: List[Int], length: Int) -> List[Int]:
    if length == 0:
        var stub = [UInt8(0)] * 1
        return keccak256_raw(UnsafePointer(to=stub[0]), 0)
    var bytes = [UInt8(0)] * length
    for i in range(length):
        bytes[i] = UInt8(data[i] & 0xFF)
    var ptr = UnsafePointer(to=bytes[0])
    return keccak256_raw(ptr, length)


fn keccak256_string(input: String) -> List[Int]:
    var data = [UInt8(0)] * len(input)
    var idx = 0
    for cp in input.codepoints():
        var value = Int(cp)
        data[idx] = UInt8(value & 0xFF)
        idx += 1
    return keccak256_bytes_from_u8(data, len(data))

fn keccak256_hex_string(input: String) -> String:
    return to_hex32(keccak256_string(input))
