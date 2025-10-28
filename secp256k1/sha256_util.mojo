from .sha256 import sha256_bytes
from .sign import bytes_to_int_be

fn sha256_bytes_to_int(data: List[Int]) -> BigInt:
    return bytes_to_int_be(sha256_bytes(data))
