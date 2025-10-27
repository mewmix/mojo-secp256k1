from .sha256 import sha256_bytes


fn hmac_sha256(key: List[Int], msg: List[Int]) -> List[Int]:
    alias BLOCK_SIZE = 64
    var k = key.copy()
    if len(k) > BLOCK_SIZE:
        k = sha256_bytes(k)

    var ipad = [0] * BLOCK_SIZE
    var opad = [0] * BLOCK_SIZE

    for idx in range(len(k)):
        var b = k[idx] & 0xFF
        ipad[idx] = b ^ 0x36
        opad[idx] = b ^ 0x5C

    for idx in range(len(k), BLOCK_SIZE):
        ipad[idx] = 0x36
        opad[idx] = 0x5C

    var inner_len = BLOCK_SIZE + len(msg)
    var inner = [0] * inner_len
    var pos = 0
    for value in ipad:
        inner[pos] = value
        pos += 1
    for value in msg:
        inner[pos] = value & 0xFF
        pos += 1

    var ih = sha256_bytes(inner)

    var outer_len = BLOCK_SIZE + len(ih)
    var outer = [0] * outer_len
    pos = 0
    for value in opad:
        outer[pos] = value
        pos += 1
    for value in ih:
        outer[pos] = value & 0xFF
        pos += 1

    return sha256_bytes(outer)


struct Rfc6979Sha256Generator(Movable):
    var K: List[Int]
    var V: List[Int]

    fn __init__(out self, msg32: List[Int], seckey32: List[Int]):
        alias OUT_LEN = 32
        self.K = [0] * OUT_LEN
        self.V = [1] * OUT_LEN
        self._update(msg32, seckey32, 0x00)
        self._update(msg32, seckey32, 0x01)

    fn _update(mut self, msg32: List[Int], seckey32: List[Int], prefix: Int):
        var total = len(self.V) + 1 + len(seckey32) + len(msg32)
        var data = [0] * total
        var pos = 0
        for value in self.V:
            data[pos] = value & 0xFF
            pos += 1
        data[pos] = prefix & 0xFF
        pos += 1
        for value in seckey32:
            data[pos] = value & 0xFF
            pos += 1
        for value in msg32:
            data[pos] = value & 0xFF
            pos += 1

        self.K = hmac_sha256(self.K, data)
        self.V = hmac_sha256(self.K, self.V)

    fn reseed(mut self):
        var data = [0] * (len(self.V) + 1)
        for i in range(len(self.V)):
            data[i] = self.V[i] & 0xFF
        data[len(self.V)] = 0
        self.K = hmac_sha256(self.K, data)
        self.V = hmac_sha256(self.K, self.V)

    fn next(mut self) -> List[Int]:
        self.V = hmac_sha256(self.K, self.V)
        return self.V.copy()


fn rfc6979_sha256(msg32: List[Int], seckey32: List[Int]) -> Rfc6979Sha256Generator:
    return Rfc6979Sha256Generator(msg32, seckey32)
