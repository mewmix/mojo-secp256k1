import subprocess
import os
import sys
import tempfile

# secp256k1 prime p
P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F

def hex_to_limbs(hex_str):
    val = int(hex_str, 16)
    return [
        (val >> 0) & 0xFFFFFFFFFFFFFFFF,
        (val >> 64) & 0xFFFFFFFFFFFFFFFF,
        (val >> 128) & 0xFFFFFFFFFFFFFFFF,
        (val >> 192) & 0xFFFFFFFFFFFFFFFF,
    ]

def limbs_to_hex(limbs):
    val = sum((limbs[i] << (64 * i)) for i in range(4))
    return f"0x{val:064x}"

def run_mojo_fuzz_iter(a_hex, b_hex):
    # Get the absolute path to the Mojo executable from the environment
    mojo_exec = os.environ.get("MOJO_EXEC")
    if not mojo_exec:
        # Fallback for manual execution, assuming pixi sets the PATH
        mojo_exec = "mojo"

    cmd = [
        mojo_exec,
        "-I", "keccak",
        "-I", ".",
        "tests/fuzz_mul.mojo",
        a_hex,
        b_hex,
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True,
            encoding='utf-8',
        )
        output = result.stdout.strip()
        # First line is mojo_res_limbs=[...]
        # Second line is python_res_limbs=[...]
        res_line = output.split('\n')[0]
        if not res_line.startswith("mojo_res_limbs="):
            raise ValueError(f"Unexpected Mojo output: {output}")
        mojo_res_hex = res_line.split("=")[1]
        return mojo_res_hex

    except subprocess.CalledProcessError as e:
        print(f"Error running Mojo subprocess: {e}", file=sys.stderr)
        print(f"Stderr: {e.stderr}", file=sys.stderr)
        return None
    except FileNotFoundError:
        print(f"Error: '{mojo_exec}' not found. Ensure Mojo SDK is in your PATH.", file=sys.stderr)
        return None

def main():
    print("Running differential fuzz test: Mojo fe_mul vs Python")
    num_iters = 1000
    for i in range(num_iters):
        a = int.from_bytes(os.urandom(32), 'big') % P
        b = int.from_bytes(os.urandom(32), 'big') % P
        a_hex = f"0x{a:064x}"
        b_hex = f"0x{b:064x}"

        mojo_res_hex = run_mojo_fuzz_iter(a_hex, b_hex)
        if mojo_res_hex is None:
            print("Mojo execution failed. Aborting.")
            sys.exit(1)

        python_res = (a * b) % P
        python_res_hex = f"0x{python_res:064x}"

        if mojo_res_hex != python_res_hex:
            print("\n" + "="*80)
            print(f"Mismatch found on iteration {i}")
            print(f"  a = {a_hex}")
            print(f"  b = {b_hex}")
            print(f"  Mojo   result: {mojo_res_hex}")
            print(f"  Python result: {python_res_hex}")
            print("="*80 + "\n")
            sys.exit(1)

        if (i+1) % 100 == 0:
            print(f"... completed {i+1}/{num_iters} iterations")

    print(f"\nSuccess! All {num_iters} fe_mul fuzz tests passed.")

if __name__ == "__main__":
    main()
