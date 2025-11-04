import subprocess
import os

def main():
    # Ensure the script is run from the root of the repository
    if not os.path.exists("pixi.toml"):
        print("Error: This script must be run from the root of the repository.")
        return

    pixi_executable = "/tmp/pixi"

    # Compile and run the mojo program to get the signed transaction
    try:
        result = subprocess.run(
            [pixi_executable, "run", "mojo", "-I", ".", "-I", "decimojo/src", "-I", "keccak", "debug_fe_mul.mojo"],
            capture_output=True,
            text=True,
            check=True,
        )
        print("Mojo output:")
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running mojo program: {e}")
        print(f"Stderr: {e.stderr}")
        return

if __name__ == "__main__":
    main()
