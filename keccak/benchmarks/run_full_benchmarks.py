#!/usr/bin/env python3
"""Aggregate Python and Mojo benchmark results into a single report."""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List


Result = Dict[str, float | str | int | None]


def _run_checked(cmd: List[str], *, cwd: Path | None = None) -> str:
    proc = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=cwd,
    )
    if proc.returncode != 0:
        message = (
            f"Command {' '.join(cmd)} failed with exit code {proc.returncode}\n"
            f"stdout:\n{proc.stdout}\n"
            f"stderr:\n{proc.stderr}"
        )
        raise SystemExit(message)
    return proc.stdout.strip()


def _format_table(results: List[Result]) -> str:
    headers = ("implementation", "seconds", "hashes/s", "checksum")
    lines = [" | ".join(headers)]
    lines.append(" | ".join("-" * len(h) for h in headers))
    for result in results:
        lines.append(
            " | ".join(
                [
                    str(result["implementation"]),
                    f"{float(result['seconds']):.6f}",
                    f"{float(result['hashes_per_second']):.2f}",
                    "-" if result.get("checksum") is None else str(result["checksum"]),
                ]
            )
        )
    return "\n".join(lines)


def _load_json(output: str) -> Result | List[Result]:
    try:
        return json.loads(output)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Failed to parse JSON output: {output}") from exc


def _ensure_tool(executable: str, message: str) -> str:
    tool = shutil.which(executable)
    if tool is None:
        raise SystemExit(message)
    return tool


def _ensure_mojo() -> str:
    return _ensure_tool(
        "mojo",
        "Unable to locate the `mojo` CLI. Activate your Pixi environment or install Mojo.",
    )


def _collect_python_results(root: Path, args: argparse.Namespace) -> List[Result]:
    cmd = [
        sys.executable,
        str(root / "benchmarks" / "run_benchmarks.py"),
        "--json",
    ]
    if args.skip_eth_hash:
        cmd.append("--skip-eth-hash")
    if args.skip_pycryptodome:
        cmd.append("--skip-pycryptodome")
    output = _run_checked(cmd, cwd=root)
    data = _load_json(output)
    if isinstance(data, dict):
        return [data]
    return list(data)


def _collect_mojo_jit(root: Path, mojo: str, args: argparse.Namespace) -> Result:
    cmd = [
        mojo,
        "-I",
        str(root),
        str(root / "benchmarks" / "mojo_benchmark.mojo"),
        "--label",
        args.mojo_jit_label,
        "--json",
    ]
    output = _run_checked(cmd, cwd=root)
    data = _load_json(output)
    if isinstance(data, list):
        raise SystemExit("Unexpected list output from Mojo JIT benchmark.")
    return data


def _collect_mojo_compiled(
    root: Path, mojo: str, args: argparse.Namespace
) -> Result:
    build_dir = root / args.build_dir
    build_dir.mkdir(parents=True, exist_ok=True)
    binary = build_dir / args.binary_name
    build_cmd = [
        mojo,
        "build",
        "-I",
        str(root),
        str(root / "benchmarks" / "mojo_benchmark.mojo"),
        "-o",
        str(binary),
    ]
    _run_checked(build_cmd, cwd=root)
    run_cmd = [
        str(binary),
        "--label",
        args.mojo_compiled_label,
        "--json",
    ]
    output = _run_checked(run_cmd, cwd=root)
    data = _load_json(output)
    if isinstance(data, list):
        raise SystemExit("Unexpected list output from Mojo compiled benchmark.")
    return data


def _collect_c_baseline(root: Path, args: argparse.Namespace) -> Result:
    compiler = _ensure_tool(
        "cc",
        "Unable to locate a C compiler (`cc`). Install one (e.g. clang or gcc) before running the C baseline.",
    )
    build_dir = root / args.build_dir
    build_dir.mkdir(parents=True, exist_ok=True)
    binary = build_dir / args.c_binary_name
    sources = [
        root / "benchmarks" / "c" / "keccak256.c",
        root / "benchmarks" / "c" / "bench_keccak256.c",
    ]
    build_cmd = [
        compiler,
        "-O3",
        "-std=c11",
        "-Wall",
        "-Wextra",
        "-Werror",
        *(str(src) for src in sources),
        "-o",
        str(binary),
    ]
    _run_checked(build_cmd, cwd=root)
    run_cmd = [
        str(binary),
        "--label",
        args.c_label,
        "--json",
    ]
    output = _run_checked(run_cmd, cwd=root)
    data = _load_json(output)
    if isinstance(data, list):
        raise SystemExit("Unexpected list output from C baseline benchmark.")
    return data


def _collect_rust_baseline(root: Path, args: argparse.Namespace) -> Result:
    _ensure_tool(
        "cargo",
        "Unable to locate `cargo`. Install Rust (https://rustup.rs/) before running the Rust baseline.",
    )
    cmd = [
        "cargo",
        "run",
        "--quiet",
        "--release",
        "--bin",
        "bench",
        "--",
        "--label",
        args.rust_label,
        "--json",
    ]
    output = _run_checked(cmd, cwd=root / "benchmarks" / "rust")
    data = _load_json(output)
    if isinstance(data, list):
        raise SystemExit("Unexpected list output from Rust baseline benchmark.")
    return data


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--skip-eth-hash",
        action="store_true",
        help="Skip the eth-hash Python baseline.",
    )
    parser.add_argument(
        "--skip-pycryptodome",
        action="store_true",
        help="Skip the PyCryptodome Python baseline.",
    )
    parser.add_argument(
        "--skip-mojo-jit",
        action="store_true",
        help="Skip the Mojo JIT benchmark.",
    )
    parser.add_argument(
        "--skip-mojo-compiled",
        action="store_true",
        help="Skip the Mojo compiled benchmark.",
    )
    parser.add_argument(
        "--skip-c",
        action="store_true",
        help="Skip the C baseline benchmark.",
    )
    parser.add_argument(
        "--skip-rust",
        action="store_true",
        help="Skip the Rust baseline benchmark.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit combined results as JSON.",
    )
    parser.add_argument(
        "--build-dir",
        default=".bench-build",
        help="Directory for compiled Mojo artifacts (default: .bench-build).",
    )
    parser.add_argument(
        "--binary-name",
        default="mojo_keccak_bench",
        help="Filename for the compiled Mojo benchmark binary.",
    )
    parser.add_argument(
        "--c-binary-name",
        default="c_keccak_bench",
        help="Filename for the compiled C benchmark binary.",
    )
    parser.add_argument(
        "--mojo-jit-label",
        default="mojo (jit)",
        help="Label to display for the Mojo JIT result.",
    )
    parser.add_argument(
        "--mojo-compiled-label",
        default="mojo (compiled)",
        help="Label to display for the Mojo compiled result.",
    )
    parser.add_argument(
        "--c-label",
        default="c (tiny-sha3)",
        help="Label to display for the C baseline.",
    )
    parser.add_argument(
        "--rust-label",
        default="rust (tiny-keccak)",
        help="Label to display for the Rust baseline.",
    )
    args = parser.parse_args(argv)

    root = Path(__file__).resolve().parents[1]
    results: List[Result] = []

    if not (args.skip_eth_hash and args.skip_pycryptodome):
        results.extend(_collect_python_results(root, args))

    if not args.skip_c:
        results.append(_collect_c_baseline(root, args))

    if not args.skip_rust:
        results.append(_collect_rust_baseline(root, args))

    if not args.skip_mojo_jit or not args.skip_mojo_compiled:
        mojo = _ensure_mojo()
        if not args.skip_mojo_jit:
            results.append(_collect_mojo_jit(root, mojo, args))
        if not args.skip_mojo_compiled:
            results.append(_collect_mojo_compiled(root, mojo, args))

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        print(_format_table(results))
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    sys.exit(main())
