from secp256k1.sign import point_mul, generator_point, pubkey_serialize_uncompressed_xy
from decimojo import BigInt

fn to_hex(data: List[Int]) -> String:
    var s = "0x"
    for b in data:
        var high = (b >> 4) & 0xf
        var low = b & 0xf
        s += chr(ord('0') + high) if high < 10 else chr(ord('a') + high - 10)
        s += chr(ord('0') + low) if low < 10 else chr(ord('a') + low - 10)
    return s

fn main() raises:
    var k = BigInt(2)
    var G = generator_point()
    var p = point_mul(k, G)
    var p_bytes = pubkey_serialize_uncompressed_xy(p)
    print(to_hex(p_bytes))

fn __main__() raises:
    main()
