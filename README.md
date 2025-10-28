# mojo-secp256k1
Deterministic secp256k1 ECDSA signing in *Mojo*, heavily supported by BigInt arithmetic  from [DeciMojo](https://github.com/forfudan/decimojo) and an sporting a *pure Mojo* [Keccak-256](https://github.com/mewmix/keccak256_mojo) implementation. 
[![CI](https://github.com/mewmix/mojo-secp256k1/actions/workflows/ci.yml/badge.svg)](https://github.com/mewmix/mojo-secp256k1/actions/workflows/ci.yml)
## Install Pixie

```bash
curl -fsSL (https://pixi.sh/install.sh) | bash
```
## Quickstart
```bashß
git clone https://mewmix/mojo-secp256k1
cd mojo-secp256k1
pixi install
pixi shell
```

## Tests

```bash
pixi run test
pixi run kat
pixi run test-kat
pixi run test-sigdump

```
Expected:
```
PASS: N signatures verified against eth-keys
```
## Notes
- As of current release, you must run Mojo with includes, example: `"-i . -I decimojo/src -I keccak`"

