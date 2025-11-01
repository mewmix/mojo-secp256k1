from collections.inline_array import InlineArray
from decimojo import BigInt
from secp256k1.field_limb import Fe, fe_from_bytes32, fe_to_bytes32, fe_mul, fe_one, fe_zero, fe_p

# Oracle function using BigInt
fn mul_oracle(a: Fe, b: Fe) raises -> Fe:
    # 1. Convert Fe to byte arrays
    var a_bytes = fe_to_bytes32(a)
    var b_bytes = fe_to_bytes32(b)

    # 2. Convert byte arrays to hex strings
    var a_hex = "0x"
    for i in range(len(a_bytes)):
        a_hex += hex(a_bytes[i])
    var b_hex = "0x"
    for i in range(len(b_bytes)):
        b_hex += hex(b_bytes[i])

    # 3. Create BigInts from hex strings
    var a_bi = BigInt(a_hex)
    var b_bi = BigInt(b_hex)
    var p_bi = BigInt("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F")

    # 4. Perform multiplication and modular reduction
    var c_bi = (a_bi * b_bi) % p_bi

    # 5. Convert result back to hex string
    var c_hex = c_bi.to_string()

    # 6. Convert hex string to byte array
    var c_bytes = List[Int]()
    # a bit hacky, but should work for now
    var c_hex_no_prefix = c_hex[2:]
    for i in range(0, len(c_hex_no_prefix), 2):
        c_bytes.append(Int(c_hex_no_prefix[i:i+2], 16))

    # 7. Convert byte array back to Fe
    return fe_from_bytes32(c_bytes)

# Cheap deterministic pseudo-random 26-bit (LCG)
struct Rng(Movable):
    var s: UInt64

    fn __init__(self, seed: UInt64) -> Self:
        var new_self = self
        new_self.s = seed
        return new_self

    fn next64(self) -> Tuple[Self, UInt64]:
        # xorshift64*
        var new_self = self
        var x = new_self.s
        x ^= x << 13; x ^= x >> 7; x ^= x << 17
        new_self.s = x
        return new_self, x

    fn next_fe(self) raises -> Tuple[Self, Fe]:
        var new_self = self
        var b = [0]*32
        var w0: UInt64; (new_self, w0) = new_self.next64()
        var w1: UInt64; (new_self, w1) = new_self.next64()
        var w2: UInt64; (new_self, w2) = new_self.next64()
        var w3: UInt64; (new_self, w3) = new_self.next64()
        # big-endian bytes for fe_from_bytes32
        var i = 0
        while i < 8:
            b[31-i] = Int((w0 >> UInt64(i*8)) & UInt64(0xFF))
            b[23-i] = Int((w1 >> UInt64(i*8)) & UInt64(0xFF))
            b[15-i] = Int((w2 >> UInt64(i*8)) & UInt64(0xFF))
            b[7 -i] = Int((w3 >> UInt64(i*8)) & UInt64(0xFF))
            i += 1
        return new_self, fe_from_bytes32(b)

fn print_fe(label: String, a: Fe):
    print(label)
    print("  v0..v3 LE:",
          a.v[0], a.v[1], a.v[2], a.v[3])

fn main() raises:
    var rng = Rng(0x12345678ABCDEF01)
    var i = 0
    while i < 200000:    # increase as needed
        var a: Fe; (rng, a) = rng.next_fe()
        var b: Fe; (rng, b) = rng.next_fe()

        var c_ref = mul_oracle(a, b)
        var c_dut = fe_mul(a, b)

        if c_ref.v[0] != c_dut.v[0] or c_ref.v[1] != c_dut.v[1] or c_ref.v[2] != c_dut.v[2] or c_ref.v[3] != c_dut.v[3]:
            print("FAIL@i=", i)
            print_fe("A", a)
            print_fe("B", b)
            print_fe("REF", c_ref)
            print_fe("DUT", c_dut)
            raise Error("fuzzer mismatch")
        i += 1
    print("OK")
