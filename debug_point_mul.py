from eth_keys.datatypes import PublicKey
from eth_keys.backends import NativeECCBackend

def main():
    g_x = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
    g_y = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
    g = PublicKey.from_point(g_x, g_y, backend=NativeECCBackend)

    p = g * 2
    print(p.to_hex())

if __name__ == "__main__":
    main()
