# mojo-secp256k1

Deterministic secp256k1 signing primitives implemented in Mojo with BigInt-backed field and scalar arithmetic. The repository vendors forks of [DeciMojo](https://github.com/forfudan/decimojo) and our Keccak-256 implementation to provide a pure Mojo playground. A top-level [pixi](https://pixi.sh) environment drives both Mojo builds and the Python reference checks.

## Prerequisites
- Mojo ≥ 0.25.7 (`mojo --version`)
- [pixi](https://pixi.sh) (install via the [official guide](https://pixi.sh/latest/#installation))
- git with submodule support

## Getting Started
1. Clone with submodules:
   ```sh
   git clone https://github.com/mewmix/mojo-secp256k1.git
   cd mojo-secp256k1
   git submodule update --init --recursive
   ```
2. Bootstrap pixi environments (once per machine):
   ```sh
   pixi install
   pixi run --cwd decimojo install
   pixi run --cwd keccak install
   ```
3. Verify the toolchain:
   ```sh
   mojo --version
   pixi --version
   ```

## Running the Test Suite
1. Activate the pixi shell (recommended):
   ```sh
   pixi shell
   ```
2. Ensure Mojo sees the BigInt and Keccak sources by extending the module search path:
   ```sh
   pixi run test
   ```
3. Expected behaviour today:
   - The test driver exercises field, scalar, and signing paths.
   - On some nightly builds the process may terminate with `Sandbox(Signal(11))` after the final test prints. Collect a stack trace with:
     ```sh
     MOJO_ENABLE_STACK_TRACE_ON_ERROR=1 pixi run test
     ```

## Development Notes
- `secp256k1/fe.mojo` and `secp256k1/sc.mojo` are now thin wrappers over DeciMojo `BigInt`. All modular reductions use `truncate_modulo` to mirror libsecp semantics for negative values.
- `secp256k1/sign.mojo` imports `keccak.keccak256` through a project-local shim so the signer stays self-contained.
- Keep the submodules aligned with the recorded commits:
  ```sh
  git submodule status
  ```
  Run `git submodule update --remote` if you intentionally advance upstream.
- Formatting and linting are currently manual; Mojo’s formatter does not yet understand BigInt-heavy code paths.

## Troubleshooting
- **Module not found** – Re-run the command with `-I . -I decimojo/src -I keccak`. Mojo does not honour submodule package roots automatically yet.
- **pixi channel SSL errors** – Ensure you trust `https://conda.modular.com` certificates or set `PIP_REQUIRE_VIRTUALENV=false` per pixi documentation. If pixi fails to install dependencies automatically, run `pixi install` followed by per-module installs inside `decimojo` and `keccak`.
- **Signal(11) after tests** – This is reproducible on `Mojo 0.25.7.0.dev2025101905`; re-run with stack traces and report upstream if it blocks your workflow.
