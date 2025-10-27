from secp256k1.sha256 import sha256_hmac


struct Rfc6979Sha256(Movable):
    var K: List[Int]
    var V: List[Int]
    var seckey: List[Int]
    var message: List[Int]

    fn __init__(out self, msg32: List[Int], seckey32: List[Int]) raises:
        if len(msg32) != 32:
            raise Error("message must be 32 bytes")
        if len(seckey32) != 32:
            raise Error("secret key must be 32 bytes")

        self.K = [0] * 32
        self.V = [1] * 32
        self.seckey = seckey32.copy()
        self.message = msg32.copy()

        self._update(0x00)
        self._update(0x01)

    fn _update(mut self, prefix: Int):
        var data = List[Int]()
        for value in self.V:
            data.append(value & 0xFF)
        data.append(prefix & 0xFF)
        for value in self.seckey:
            data.append(value & 0xFF)
        for value in self.message:
            data.append(value & 0xFF)

        self.K = sha256_hmac(self.K, data)
        self.V = sha256_hmac(self.K, self.V)

    fn reseed(mut self):
        var data = self.V.copy()
        data.append(0x00)
        self.K = sha256_hmac(self.K, data)
        self.V = sha256_hmac(self.K, self.V)

    fn next(mut self) -> List[Int]:
        self.V = sha256_hmac(self.K, self.V)
        return self.V.copy()


fn rfc6979_sha256(msg32: List[Int], seckey32: List[Int]) raises -> Rfc6979Sha256:
    return Rfc6979Sha256(msg32, seckey32)
