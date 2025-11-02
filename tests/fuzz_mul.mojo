from secp256k1.field_limb import Fe, fe_from_limbs, fe_mul
from sys import argv
from collections.inline_array import InlineArray

fn hex_char_to_u4(c: UInt8) -> UInt8:
    if c >= ord('0') and c <= ord('9'):
        return c - ord('0')
    if c >= ord('a') and c <= ord('f'):
        return c - ord('a') + 10
    if c >= ord('A') and c <= ord('F'):
        return c - ord('A') + 10
    return 255 # error indicator

fn fe_from_hex(hex_str: String) -> Fe:
    # Expects "0x" + 64 hex chars
    var limbs = InlineArray[UInt64, 4](0, 0, 0, 0)
    var str_len = len(hex_str)
    if str_len != 66:
        print("Error: fe_from_hex expects '0x' + 64 hex chars")
        return fe_from_limbs(limbs)

    var bytes_str = hex_str.as_bytes()
    @parameter
    for i in range(4): # 4 limbs
        var current_limb: UInt64 = 0
        @parameter
        for j in range(16): # 16 hex chars per limb
            var char_idx = str_len - 1 - (i * 16 + j)
            var u4_val = hex_char_to_u4(bytes_str[char_idx])
            current_limb |= UInt64(u4_val) << UInt64(j * 4)
        limbs[i] = current_limb
    return fe_from_limbs(limbs)

fn fe_to_hex(f: Fe) -> String:
    var s = "0x"
    @parameter
    for i in range(4):
        var limb_idx = 3 - i
        var limb = f.v[limb_idx]
        var part = ""
        @parameter
        for j in range(16):
            var char_idx = 15 - j
            var u4 = (limb >> UInt64(char_idx * 4)) & 0xF
            if u4 < 10:
                part += chr(ord('0') + Int(u4))
            else:
                part += chr(ord('a') + Int(u4) - 10)
        s += part
    return s

fn main() raises:
    var args = argv()
    if len(args) != 3:
        print("Usage: mojo fuzz_mul.mojo <hex_a> <hex_b>")
        return

    var a = fe_from_hex(args[1])
    var b = fe_from_hex(args[2])
    var c = fe_mul(a, b)
    var c_hex = fe_to_hex(c)
    print("mojo_res_limbs=" + c_hex)
