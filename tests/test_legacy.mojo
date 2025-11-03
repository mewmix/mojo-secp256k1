from secp256k1.sign import ecdsa_sign_keccak, SigCompact, bytes_to_int_be, int_to_bytes32_be
from keccak import keccak256_bytes

fn to_hex32(b: List[Int]) -> String:
    var out = String("")
    var hexd = "0123456789abcdef"
    @parameter
    for i in range(32):
        var v = b[i] & 0xFF
        out += String(hexd[v >> 4]) + String(hexd[v & 0xF])
    return out

fn to_hex(bs: List[Int]) -> String:
    var out = String("")
    var hexd = "0123456789abcdef"
    for v in bs:
        var x = v & 0xFF
        out += String(hexd[x >> 4]) + String(hexd[x & 0xF])
    return out

fn hex_nibble(c: Int) -> Int:
    if 48 <= c <= 57:   return c - 48
    if 97 <= c <= 102:  return c - 87
    if 65 <= c <= 70:   return c - 55
    return 0

fn hex_to_bytes(hex: String) -> List[Int]:
    var s = hex
    if len(s) >= 2 and s[0] == '0' and (s[1] == 'x' or s[1] == 'X'):
        s = s[2:]
    var out = List[Int]()
    var i = 0
    while i < len(s):
        var hi = hex_nibble(ord(s[i]))
        var lo = hex_nibble(ord(s[i+1]))
        out.append(((hi << 4) | lo) & 0xFF)
        i += 2
    return out.copy()

# RLP encoder
fn rlp_encode_bytes(data: List[Int]) -> List[Int]:
    var len_data = len(data)
    if len_data == 1 and data[0] < 0x80:
        return data.copy()
    elif len_data <= 55:
        var encoded = List[Int]()
        encoded.append(0x80 + len_data)
        for i in range(len_data):
            encoded.append(data[i])
        return encoded.copy()
    else:
        var encoded_len = List[Int]()
        var temp_len = len_data
        while temp_len > 0:
            encoded_len.append(temp_len & 0xFF)
            temp_len //= 256

        var reversed_encoded_len = List[Int]()
        for i in range(len(encoded_len)-1, -1, -1):
            reversed_encoded_len.append(encoded_len[i])

        var final_encoded = List[Int]()
        final_encoded.append(0xb7 + len(reversed_encoded_len))
        for i in range(len(reversed_encoded_len)):
            final_encoded.append(reversed_encoded_len[i])
        for i in range(len_data):
            final_encoded.append(data[i])
        return final_encoded.copy()

fn int_to_list(n: Int) -> List[Int]:
    if n == 0:
        return List[Int]()
    var result = List[Int]()
    var temp = n
    while temp > 0:
        result.append(temp & 0xff)
        temp >>= 8

    var reversed_result = List[Int]()
    for i in range(len(result)-1, -1, -1):
        reversed_result.append(result[i])
    return reversed_result.copy()

fn rlp_encode_list(items: List[List[Int]]) -> List[Int]:
    var payload = List[Int]()
    for item in items:
        payload.extend(rlp_encode_bytes(item))

    var rlp_encoded_tx = List[Int]()
    var len_payload = len(payload)
    if len_payload <= 55:
        rlp_encoded_tx.append(0xc0 + len_payload)
    else:
        var encoded_len = List[Int]()
        var temp_len = len_payload
        while temp_len > 0:
            encoded_len.append(temp_len & 0xFF)
            temp_len //= 256

        var reversed_encoded_len = List[Int]()
        for i in range(len(encoded_len)-1, -1, -1):
            reversed_encoded_len.append(encoded_len[i])

        rlp_encoded_tx.append(0xf7 + len(reversed_encoded_len))
        for i in range(len(reversed_encoded_len)):
            rlp_encoded_tx.append(reversed_encoded_len[i])

    rlp_encoded_tx.extend(payload.copy())
    return rlp_encoded_tx.copy()


fn main() raises:
    # Legacy Transaction details
    var nonce = int_to_list(0)
    var gas_price = int_to_list(20000000000) # 20 Gwei
    var gas_limit = int_to_list(21000)
    var to_str = "0x7f5c7c5abC18ACF65DBFAD8bB9fF487f47fF83e4"
    var to = hex_to_bytes(to_str)
    var value = int_to_list(1000000000000000000) # 1 ETH
    var data = List[Int]()
    var chain_id = 1

    # Private key
    var sk_hex = "0x4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318"
    var sk_bytes = hex_to_bytes(sk_hex)

    # RLP encode the transaction payload
    var unsigned_tx_items = List[List[Int]]()
    unsigned_tx_items.append(nonce.copy())
    unsigned_tx_items.append(gas_price.copy())
    unsigned_tx_items.append(gas_limit.copy())
    unsigned_tx_items.append(to.copy())
    unsigned_tx_items.append(value.copy())
    unsigned_tx_items.append(data.copy())
    unsigned_tx_items.append(int_to_list(chain_id))
    unsigned_tx_items.append(int_to_list(0))
    unsigned_tx_items.append(int_to_list(0))

    var rlp_encoded_unsigned_tx = rlp_encode_list(unsigned_tx_items)

    # Hash the transaction
    var msg32 = keccak256_bytes(rlp_encoded_unsigned_tx, len(rlp_encoded_unsigned_tx))

    # Sign the transaction
    var sig = ecdsa_sign_keccak(msg32, sk_bytes)
    var v = sig.v + 35 + chain_id * 2

    # RLP encode the signed transaction
    var signed_tx_items = List[List[Int]]()
    signed_tx_items.append(nonce.copy())
    signed_tx_items.append(gas_price.copy())
    signed_tx_items.append(gas_limit.copy())
    signed_tx_items.append(to.copy())
    signed_tx_items.append(value.copy())
    signed_tx_items.append(data.copy())
    signed_tx_items.append(int_to_list(v))
    var r_bytes = List[Int]()
    for i in range(32):
        r_bytes.append(sig.r[i])
    signed_tx_items.append(r_bytes.copy())
    var s_bytes = List[Int]()
    for i in range(32):
        s_bytes.append(sig.s[i])
    signed_tx_items.append(s_bytes.copy())

    var rlp_encoded_signed_tx = rlp_encode_list(signed_tx_items)


    # Print the signature
    print("idx\tsk_hex\tmsg_hex\tmsg32_hex\tr_hex\ts_hex\tv\tsigned_tx_hex")
    print(
        "0" + "\t" + sk_hex + "\t" + to_hex(rlp_encoded_unsigned_tx) + "\t" +
        to_hex32(msg32) + "\t" + to_hex32(sig.r) + "\t" + to_hex32(sig.s) +
        "\t" + String(v) + "\t" + to_hex(rlp_encoded_signed_tx)
    )
