"""
Comprehensive benchmarks for Decimal128 multiplication operations.
Compares performance against Python's decimal module.
"""

from decimojo.prelude import dm, Decimal128, RoundingMode
from python import Python, PythonObject
from time import perf_counter_ns
import time
import os


fn open_log_file() raises -> PythonObject:
    """
    Creates and opens a log file with a timestamp in the filename.

    Returns:
        A file object opened for writing.
    """
    var python = Python.import_module("builtins")
    var datetime = Python.import_module("datetime")

    # Create logs directory if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate a timestamp for the filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = log_dir + "/benchmark_multiply_" + timestamp + ".log"

    print("Saving benchmark results to:", log_filename)
    return python.open(log_filename, "w")


fn log_print(msg: String, log_file: PythonObject) raises:
    """
    Prints a message to both the console and the log file.

    Args:
        msg: The message to print.
        log_file: The file object to write to.
    """
    print(msg)
    log_file.write(msg + "\n")
    log_file.flush()  # Ensure the message is written immediately


fn run_benchmark(
    name: String,
    a_mojo: Decimal128,
    b_mojo: Decimal128,
    a_py: PythonObject,
    b_py: PythonObject,
    iterations: Int,
    log_file: PythonObject,
) raises:
    """
    Run a benchmark comparing Mojo Dec128 multiplication with Python decimal multiplication.

    Args:
        name: Name of the benchmark case.
        a_mojo: First Mojo Dec128 operand.
        b_mojo: Second Mojo Dec128 operand.
        a_py: First Python decimal operand.
        b_py: Second Python decimal operand.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
    """
    log_print("\nBenchmark:       " + name, log_file)

    # Verify correctness
    var mojo_result = a_mojo * b_mojo
    var py_result = a_py * b_py
    log_print(
        "Decimals:        " + String(a_mojo) + " * " + String(b_mojo), log_file
    )
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = a_mojo * b_mojo
    var mojo_time = (perf_counter_ns() - t0) / iterations

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = a_py * b_py
    var python_time = (perf_counter_ns() - t0) / iterations

    # Print results with speedup comparison
    log_print(
        "Mojo decimal:    " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python decimal:  " + String(python_time) + " ns per iteration",
        log_file,
    )
    log_print("Speedup factor:  " + String(python_time / mojo_time), log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Display benchmark header with system information
    log_print("=== DeciMojo Multiplication Benchmark ===", log_file)
    log_print("Time: " + String(datetime.datetime.now().isoformat()), log_file)

    # Try to get system info
    try:
        var platform = Python.import_module("platform")
        log_print(
            "System: "
            + String(platform.system())
            + " "
            + String(platform.release()),
            log_file,
        )
        log_print("Processor: " + String(platform.processor()), log_file)
        log_print(
            "Python version: " + String(platform.python_version()), log_file
        )
    except:
        log_print("Could not retrieve system information", log_file)

    var iterations = 1000
    var pydecimal = Python().import_module("decimal")

    # Set Python decimal precision to match Mojo's
    pydecimal.getcontext().prec = 28
    log_print(
        "Python decimal precision: " + String(pydecimal.getcontext().prec),
        log_file,
    )
    log_print(
        "Mojo decimal precision: " + String(Decimal128.MAX_SCALE), log_file
    )

    # Define benchmark cases
    log_print(
        "\nRunning multiplication benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Small integers
    var case1_a_mojo = Decimal128("12")
    var case1_b_mojo = Decimal128("34")
    var case1_a_py = pydecimal.Decimal128("12")
    var case1_b_py = pydecimal.Decimal128("34")
    run_benchmark(
        "Small integers",
        case1_a_mojo,
        case1_b_mojo,
        case1_a_py,
        case1_b_py,
        iterations,
        log_file,
    )

    # Case 2: Simple decimals
    var case2_a_mojo = Decimal128("12.34")
    var case2_b_mojo = Decimal128("5.67")
    var case2_a_py = pydecimal.Decimal128("12.34")
    var case2_b_py = pydecimal.Decimal128("5.67")
    run_benchmark(
        "Simple decimals",
        case2_a_mojo,
        case2_b_mojo,
        case2_a_py,
        case2_b_py,
        iterations,
        log_file,
    )

    # Case 3: Different scales
    var case3_a_mojo = Decimal128("12.3")
    var case3_b_mojo = Decimal128("4.56")
    var case3_a_py = pydecimal.Decimal128("12.3")
    var case3_b_py = pydecimal.Decimal128("4.56")
    run_benchmark(
        "Different scales",
        case3_a_mojo,
        case3_b_mojo,
        case3_a_py,
        case3_b_py,
        iterations,
        log_file,
    )

    # Case 4: Multiplication by zero
    var case4_a_mojo = Decimal128("123.45")
    var case4_b_mojo = Decimal128("0")
    var case4_a_py = pydecimal.Decimal128("123.45")
    var case4_b_py = pydecimal.Decimal128("0")
    run_benchmark(
        "Multiplication by zero",
        case4_a_mojo,
        case4_b_mojo,
        case4_a_py,
        case4_b_py,
        iterations,
        log_file,
    )

    # Case 5: Multiplication by one
    var case5_a_mojo = Decimal128("123.45")
    var case5_b_mojo = Decimal128("1")
    var case5_a_py = pydecimal.Decimal128("123.45")
    var case5_b_py = pydecimal.Decimal128("1")
    run_benchmark(
        "Multiplication by one",
        case5_a_mojo,
        case5_b_mojo,
        case5_a_py,
        case5_b_py,
        iterations,
        log_file,
    )

    # Case 6: Negative numbers
    var case6_a_mojo = Decimal128("12.34")
    var case6_b_mojo = Decimal128("-5.67")
    var case6_a_py = pydecimal.Decimal128("12.34")
    var case6_b_py = pydecimal.Decimal128("-5.67")
    run_benchmark(
        "Negative numbers",
        case6_a_mojo,
        case6_b_mojo,
        case6_a_py,
        case6_b_py,
        iterations,
        log_file,
    )

    # Case 7: High precision
    var case7_a_mojo = Decimal128("0.12345678901234567")
    var case7_b_mojo = Decimal128("0.98765432109876543")
    var case7_a_py = pydecimal.Decimal128("0.12345678901234567")
    var case7_b_py = pydecimal.Decimal128("0.98765432109876543")
    run_benchmark(
        "High precision multiplication",
        case7_a_mojo,
        case7_b_mojo,
        case7_a_py,
        case7_b_py,
        iterations,
        log_file,
    )

    # Case 8: Large integer multiplication
    var case8_a_mojo = Decimal128("123456789")
    var case8_b_mojo = Decimal128("987654321")
    var case8_a_py = pydecimal.Decimal128("123456789")
    var case8_b_py = pydecimal.Decimal128("987654321")
    run_benchmark(
        "Large integer multiplication",
        case8_a_mojo,
        case8_b_mojo,
        case8_a_py,
        case8_b_py,
        iterations,
        log_file,
    )

    # Case 9: Fractional multiplication resulting in very small scale
    var case9_a_mojo = Decimal128("0.01")
    var case9_b_mojo = Decimal128("0.01")
    var case9_a_py = pydecimal.Decimal128("0.01")
    var case9_b_py = pydecimal.Decimal128("0.01")
    run_benchmark(
        "Fractional multiplication",
        case9_a_mojo,
        case9_b_mojo,
        case9_a_py,
        case9_b_py,
        iterations,
        log_file,
    )

    # Case 10: Powers of 10
    var case10_a_mojo = Decimal128("10")
    var case10_b_mojo = Decimal128("10")
    var case10_a_py = pydecimal.Decimal128("10")
    var case10_b_py = pydecimal.Decimal128("10")
    run_benchmark(
        "Powers of 10",
        case10_a_mojo,
        case10_b_mojo,
        case10_a_py,
        case10_b_py,
        iterations,
        log_file,
    )

    # Case 11: Decimal128 multiplication with many digits after the decimal point
    var case11_a_mojo = Decimal128.E()
    var case11_b_mojo = dm.decimal128.constants.E0D5()
    var case11_a_py = pydecimal.Decimal128("1").exp()
    var case11_b_py = pydecimal.Decimal128("0.5").exp()
    run_benchmark(
        "e * e^0.5",
        case11_a_mojo,
        case11_b_mojo,
        case11_a_py,
        case11_b_py,
        iterations,
        log_file,
    )

    # Display summary
    log_print("\n=== Multiplication Benchmark Summary ===", log_file)
    log_print("Benchmarked:      11 different multiplication cases", log_file)
    log_print(
        "Each case ran:    " + String(iterations) + " iterations", log_file
    )
    log_print(
        "Performance:      See detailed results above for each case", log_file
    )

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
