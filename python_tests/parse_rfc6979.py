import re
import json

def parse_rfc6979_vectors(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Find all P-256 test cases
    p256_section = re.search(r"Title = RFC 6979 P-256 deterministic ECDSA tests(.+?)(?=Title)", content, re.DOTALL)
    if not p256_section:
        return []

    test_cases = []

    # Extract private key

    priv_key_match = re.search(r"-----BEGIN PRIVATE KEY-----\s*(.*?)\s*-----END PRIVATE KEY-----", p256_section.group(1), re.DOTALL)
    priv_key = priv_key_match.group(1).strip().replace("\n", "")

    # Extract test cases
    for match in re.finditer(r"DigestSign = (.*?)\nKey = (.*?)\nNonceType = (.*?)\nInput = \"(.*?)\"\nOutput = (.*?)\n", p256_section.group(1)):
        test_cases.append({
            "digest": match.group(1),
            "key": priv_key,
            "nonce_type": match.group(3),
            "input": match.group(4),
            "output": match.group(5),
        })

    return test_cases

if __name__ == "__main__":
    vectors = parse_rfc6979_vectors("external/cryptography/vectors/cryptography_vectors/asymmetric/ECDSA/RFC6979/evppkey_ecdsa_rfc6979.txt")
    with open("tests/rfc6979_p256.json", "w") as f:
        json.dump(vectors, f, indent=2)
