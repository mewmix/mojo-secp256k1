from decimojo import BigInt

fn hex_char_to_int(c: Int) -> Int:
    if 48 <= c <= 57:
        return c - 48
    if 97 <= c <= 102:
        return c - 87
    if 65 <= c <= 70:
        return c - 55
    return 0

fn hex_to_bigint(hex_str: String) -> BigInt:
    var result = BigInt(0)
    var s = hex_str
    if len(s) >= 2 and s[0] == '0' and (s[1] == 'x' or s[1] == 'X'):
        s = s[2:]

    for char_code in s.codepoints():
        result = result * BigInt(16) + BigInt(hex_char_to_int(Int(char_code)))
    return result
