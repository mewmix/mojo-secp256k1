#!/usr/bin/env python3
"""Benchmark Mojo ECDSA primitives against Python and libsecp256k1 bindings."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import Dict, List

from eth_keys import keys
from eth_utils.crypto import keccak
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import Prehashed

DEFAULT_ITERATIONS = 50
MOJO_BIN = os.path.join(os.path.dirname(sys.executable), "mojo")
MOJO_CMD = [
    MOJO_BIN,
    "-I",
    "decimojo/src",
    "-I",
    "keccak",
    "-I",
    ".",
    "bench_ecdsa.mojo",
]


def run_subprocess(cmd: List[str], env: Dict[str, str] | None = None) -> str:
    proc = subprocess.run(
        cmd,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
    )
    if proc.stderr:
        print(proc.stderr, file=sys.stderr)
    return proc.stdout


@dataclass
class BenchResult:
    implementation: str
    sign_ns: float
    recover_ns: float

    @property
    def sign_per_sec(self) -> float:
        return 1_000_000_000.0 / self.sign_ns

    @property
    def recover_per_sec(self) -> float:
        return 1_000_000_000.0 / self.recover_ns


def parse_mojo_output(stdout: str) -> BenchResult:
    values: Dict[str, float] = {}
    for line in stdout.splitlines():
        if "=" not in line:
            continue
        key, raw = line.split("=", 1)
        key = key.strip()
        try:
            values[key] = float(raw.strip())
        except ValueError:
            continue
    try:
        sign_ns = values["mojo.sign_ns_per_iter"]
        recover_ns = values["mojo.recover_ns_per_iter"]
    except KeyError as exc:  # pragma: no cover - defensive
        raise RuntimeError(f"missing benchmark output field: {exc}") from exc
    return BenchResult("mojo", sign_ns, recover_ns)


def bench_mojo(iterations: int) -> BenchResult:
    env = os.environ.copy()
    env["PYTHONPATH"] = os.getcwd()
    modular_home = os.environ.get("MODULAR_HOME")
    if modular_home:
        env["MODULAR_HOME"] = modular_home
    env["MOJO_BENCH_ITERATIONS"] = str(iterations)
    stdout = run_subprocess(MOJO_CMD, env=env)
    return parse_mojo_output(stdout)


def bench_eth_keys(iterations: int) -> BenchResult:
    private_key = keys.PrivateKey(os.urandom(32))
    message_hash = keccak(b"benchmark message")

    start = time.perf_counter_ns()
    for _ in range(iterations):
        private_key.sign_msg_hash(message_hash)
    sign_ns = (time.perf_counter_ns() - start) / iterations

    signature = private_key.sign_msg_hash(message_hash)
    start = time.perf_counter_ns()
    for _ in range(iterations):
        signature.recover_public_key_from_msg_hash(message_hash)
    recover_ns = (time.perf_counter_ns() - start) / iterations

    return BenchResult("eth-keys (Python)", sign_ns, recover_ns)


def bench_cryptography(iterations: int) -> BenchResult:
    private_key = ec.generate_private_key(ec.SECP256K1())
    message = b"benchmark message"
    digest = keccak(message)
    algorithm = Prehashed(hashes.SHA256())
    ecdsa_algorithm = ec.ECDSA(algorithm)

    start = time.perf_counter_ns()
    for _ in range(iterations):
        private_key.sign(digest, ecdsa_algorithm)
    sign_ns = (time.perf_counter_ns() - start) / iterations

    signature = private_key.sign(digest, ecdsa_algorithm)
    public_key = private_key.public_key()
    start = time.perf_counter_ns()
    for _ in range(iterations):
        public_key.verify(signature, digest, ecdsa_algorithm)
    recover_ns = (time.perf_counter_ns() - start) / iterations

    return BenchResult("cryptography (OpenSSL)", sign_ns, recover_ns)


def format_table(results: List[BenchResult]) -> str:
    headers = ("Implementation", "Sign (ns)", "Sign/s", "Recover (ns)", "Recover/s")
    rows = [
        (
            r.implementation,
            f"{r.sign_ns:,.0f}",
            f"{r.sign_per_sec:,.0f}",
            f"{r.recover_ns:,.0f}",
            f"{r.recover_per_sec:,.0f}",
        )
        for r in results
    ]
    widths = [max(len(headers[i]), *(len(row[i]) for row in rows)) for i in range(len(headers))]
    def fmt_row(row):
        return " | ".join(val.ljust(widths[i]) for i, val in enumerate(row))
    lines = [fmt_row(headers), " | ".join("-" * w for w in widths)]
    lines.extend(fmt_row(row) for row in rows)
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iterations", type=int, default=DEFAULT_ITERATIONS, help="Number of iterations per benchmark")
    args = parser.parse_args()

    iterations = max(1, args.iterations)
    results = [
        bench_mojo(iterations),
        bench_eth_keys(iterations),
        bench_cryptography(iterations),
    ]

    print(format_table(results))

    payload = {
        "iterations": iterations,
        "results": [
            {
                "implementation": r.implementation,
                "sign_ns": r.sign_ns,
                "recover_ns": r.recover_ns,
                "sign_per_sec": r.sign_per_sec,
                "recover_per_sec": r.recover_per_sec,
            }
            for r in results
        ],
    }
    print("\nJSON:")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
