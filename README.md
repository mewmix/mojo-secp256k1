# mojo-secp256k1

[![CI](https://github.com/mewmix/mojo-secp256k1/actions/workflows/ci.yml/badge.svg)](https://github.com/mewmix/mojo-secp256k1/actions/workflows/ci.yml)

This project is built upon a *pure* Mojo [Keccak-256](https://github.com/mewmix/keccak256_mojo) implementation and heavily wraps [DeciMojo](https://github.com/forfudan/decimojo) for BigInt support.

## Prerequisites
- Pixi (used to manage Mojo/Conda environments)

## Install Pixi

```bash
curl -fsSL https://pixi.sh/install.sh | bash
export PATH="$HOME/.pixi/bin:$PATH"
```

## Quickstart

```bash
git clone https://github.com/mewmix/mojo-secp256k1.git
cd mojo-secp256k1
pixi install       
pixi run ci      
```

## Usage 
```bash
# core tests
mojo -I decimojo/src -I keccak test_secp256k1.mojo

# recovery tests
mojo -I . -I decimojo/src -I keccak test_ecdsa_recover.mojo
```

## Tests

Run the project's test suite via Pixi:

```bash
pixi run test
```
## Notes

- When running Mojo directly, include the necessary paths. Example includes: `-I decimojo/src -I keccak`.



