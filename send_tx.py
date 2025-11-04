import json
import os
import shutil
import subprocess
from typing import List

import requests


def main():
    # Ensure the script is run from the root of the repository
    if not os.path.exists("pixi.toml"):
        print("Error: This script must be run from the root of the repository.")
        return

    pixi_executable = shutil.which("pixi") or "/tmp/pixi"

    if not os.path.exists(pixi_executable):
        print("Error: Could not find pixi executable. Ensure Pixi is installed and in PATH.")
        return

    mojo_command: List[str] = [
        pixi_executable,
        "run",
        "mojo",
        "-I",
        ".",
        "-I",
        "decimojo/src",
        "-I",
        "keccak",
        "create_signed_tx.mojo",
    ]

    # Compile and run the mojo program to get the signed transaction
    try:
        result = subprocess.run(mojo_command, capture_output=True, text=True, check=True)
        mojo_output = result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running mojo program: {e}")
        print(f"Stderr: {e.stderr}")
        return

    if not mojo_output:
        print("Mojo program produced no output. Cannot construct transaction.")
        return

    try:
        tx_bytes = bytes(int(part) for part in mojo_output.split())
    except ValueError as exc:
        print(f"Failed to parse Mojo output into bytes: {exc}")
        print(f"Raw Mojo output: {mojo_output}")
        return

    raw_tx_hex = "0x" + tx_bytes.hex()
    print(f"Signed transaction: {raw_tx_hex}")

    payload = {
        "jsonrpc": "2.0",
        "method": "eth_sendRawTransaction",
        "params": [raw_tx_hex],
        "id": 1,
    }

    try:
        response = requests.post("http://127.0.0.1:8545", json=payload, timeout=10)
        response.raise_for_status()
    except requests.RequestException as exc:
        print(f"Failed to send transaction to Anvil node: {exc}")
        return

    try:
        rpc_response = response.json()
    except json.JSONDecodeError:
        print("Node returned non-JSON response:")
        print(response.text)
        return

    print("RPC response:")
    print(json.dumps(rpc_response, indent=2))


if __name__ == "__main__":
    main()
