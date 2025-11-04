from secp256k1.sign import ecdsa_sign_keccak, int_to_bytes
from keccak import keccak256_bytes
from decimojo import BigInt

fn hex_to_int(hex_char: String) -> Int:
    for c in hex_char.lower().codepoints():
        var c_int = Int(c)
        if c_int >= ord('0') and c_int <= ord('9'):
            return c_int - ord('0')
        elif c_int >= ord('a') and c_int <= ord('f'):
            return c_int - ord('a') + 10
        else:
            return -1
    return -1

fn rlp_encode_bytes(data: List[Int]) raises -> List[Int]:
    var n = len(data)
    if n == 1 and data[0] < 0x80:
        return data.copy()

    var prefix = List[Int]()
    if n <= 55:
        prefix.append(0x80 + n)
    else:
        var len_bytes = int_to_bytes(BigInt(n))
        prefix.append(0xb7 + len(len_bytes))
        prefix.extend(len_bytes.copy())

    prefix.extend(data.copy())
    return prefix.copy()

fn rlp_encode_list(items: List[List[Int]]) raises -> List[Int]:
    var payload = List[Int]()
    for item in items:
        if len(item) == 0:
            payload.append(0x80)
        elif len(item) == 1 and item[0] == 0:
            payload.append(0x80)
        else:
            payload.extend(rlp_encode_bytes(item.copy()))

    var prefix = List[Int]()
    var n = len(payload)
    if n <= 55:
        prefix.append(0xc0 + n)
    else:
        var len_bytes = int_to_bytes(BigInt(n))
        prefix.append(0xf7 + len(len_bytes))
        prefix.extend(len_bytes.copy())

    prefix.extend(payload.copy())
    return prefix.copy()

fn main() raises:
    var sk_hex = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    var sk = List[Int]()
    for i in range(2, len(sk_hex), 2):
        var high = hex_to_int(sk_hex[i:i+1])
        var low = hex_to_int(sk_hex[i+1:i+2])
        sk.append(high * 16 + low)

    var nonce = BigInt(1)
    var gas_price = BigInt(20000000000)
    var gas_limit = BigInt(21000)
    var to_hex = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    var to = List[Int]()
    for i in range(2, len(to_hex), 2):
        var high = hex_to_int(to_hex[i:i+1])
        var low = hex_to_int(to_hex[i+1:i+2])
        to.append(high * 16 + low)

    var value = BigInt(1000000000000000000)
    var data = List[Int]()
    var chain_id = 31337

    # RLP encode the unsigned transaction for signing
    var unsigned_tx_signing = List[List[Int]](
        int_to_bytes(nonce),
        int_to_bytes(gas_price),
        int_to_bytes(gas_limit),
        to.copy(),
        int_to_bytes(value),
        data.copy(),
        int_to_bytes(BigInt(chain_id)),
        List[Int](),
        List[Int](),
    )
    var rlp_unsigned_tx_signing = rlp_encode_list(unsigned_tx_signing)

    var msg32 = keccak256_bytes(rlp_unsigned_tx_signing, len(rlp_unsigned_tx_signing))

    var sig = ecdsa_sign_keccak(msg32, sk)

    # RLP encode the signed transaction
    var eip155_v = BigInt((sig.v - 27) + chain_id * 2 + 35)
    var signed_tx = List[List[Int]](
        int_to_bytes(nonce),
        int_to_bytes(gas_price),
        int_to_bytes(gas_limit),
        to.copy(),
        int_to_bytes(value),
        data.copy(),
        int_to_bytes(eip155_v),
        sig.r.copy(),
        sig.s.copy(),
    )
    var rlp_signed_tx = rlp_encode_list(signed_tx)

    for b in rlp_signed_tx:
        print(b, end=" ")

fn __main__() raises:
    main()
