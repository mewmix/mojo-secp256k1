"""
Comprehensive benchmarks for Decimal128 division operations.
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
    var log_filename = log_dir + "/benchmark_divide_" + timestamp + ".log"

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
    Run a benchmark comparing Mojo Dec128 division with Python decimal division.

    Args:
        name: Name of the benchmark case.
        a_mojo: First Mojo Dec128 operand (dividend).
        b_mojo: Second Mojo Dec128 operand (divisor).
        a_py: First Python decimal operand.
        b_py: Second Python decimal operand.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print(
        "Decimals:        " + String(a_mojo) + " / " + String(b_mojo), log_file
    )

    # Verify correctness
    var mojo_result = a_mojo / b_mojo
    var py_result = a_py / b_py
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = a_mojo / b_mojo
    var mojo_time = (perf_counter_ns() - t0) / iterations

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = a_py / b_py
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
    log_print("=== DeciMojo Division Benchmark ===", log_file)
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
        "\nRunning division benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Simple integer division with no remainder
    var case1_a_mojo = Decimal128("100")
    var case1_b_mojo = Decimal128("4")
    var case1_a_py = pydecimal.Decimal128("100")
    var case1_b_py = pydecimal.Decimal128("4")
    run_benchmark(
        "Integer division (no remainder)",
        case1_a_mojo,
        case1_b_mojo,
        case1_a_py,
        case1_b_py,
        iterations,
        log_file,
    )

    # Case 2: Division with simple decimals
    var case2_a_mojo = Decimal128("10.5")
    var case2_b_mojo = Decimal128("2.5")
    var case2_a_py = pydecimal.Decimal128("10.5")
    var case2_b_py = pydecimal.Decimal128("2.5")
    run_benchmark(
        "Simple decimal division",
        case2_a_mojo,
        case2_b_mojo,
        case2_a_py,
        case2_b_py,
        iterations,
        log_file,
    )

    # Case 3: Division with repeating decimal result
    var case3_a_mojo = Decimal128("10")
    var case3_b_mojo = Decimal128("3")
    var case3_a_py = pydecimal.Decimal128("10")
    var case3_b_py = pydecimal.Decimal128("3")
    run_benchmark(
        "Division with repeating decimal",
        case3_a_mojo,
        case3_b_mojo,
        case3_a_py,
        case3_b_py,
        iterations,
        log_file,
    )

    # Case 4: Division by one (identity)
    var case4_a_mojo = Decimal128("123.45")
    var case4_b_mojo = Decimal128("1")
    var case4_a_py = pydecimal.Decimal128("123.45")
    var case4_b_py = pydecimal.Decimal128("1")
    run_benchmark(
        "Division by one",
        case4_a_mojo,
        case4_b_mojo,
        case4_a_py,
        case4_b_py,
        iterations,
        log_file,
    )

    # Case 5: Division of zero by non-zero
    var case5_a_mojo = Decimal128("0")
    var case5_b_mojo = Decimal128("123.45")
    var case5_a_py = pydecimal.Decimal128("0")
    var case5_b_py = pydecimal.Decimal128("123.45")
    run_benchmark(
        "Division of zero",
        case5_a_mojo,
        case5_b_mojo,
        case5_a_py,
        case5_b_py,
        iterations,
        log_file,
    )

    # Case 6: Division with negative numbers
    var case6_a_mojo = Decimal128("123.45")
    var case6_b_mojo = Decimal128("-2")
    var case6_a_py = pydecimal.Decimal128("123.45")
    var case6_b_py = pydecimal.Decimal128("-2")
    run_benchmark(
        "Division with negative numbers",
        case6_a_mojo,
        case6_b_mojo,
        case6_a_py,
        case6_b_py,
        iterations,
        log_file,
    )

    # Case 7: Division with very small divisor
    var case7_a_mojo = Decimal128("1")
    var case7_b_mojo = Decimal128("0.0001")
    var case7_a_py = pydecimal.Decimal128("1")
    var case7_b_py = pydecimal.Decimal128("0.0001")
    run_benchmark(
        "Division by very small number",
        case7_a_mojo,
        case7_b_mojo,
        case7_a_py,
        case7_b_py,
        iterations,
        log_file,
    )

    # Case 8: Division with high precision
    var case8_a_mojo = Decimal128("0.1234567890123456789")
    var case8_b_mojo = Decimal128("0.0987654321098765432")
    var case8_a_py = pydecimal.Decimal128("0.1234567890123456789")
    var case8_b_py = pydecimal.Decimal128("0.0987654321098765432")
    run_benchmark(
        "High precision division",
        case8_a_mojo,
        case8_b_mojo,
        case8_a_py,
        case8_b_py,
        iterations,
        log_file,
    )

    # Case 9: Division resulting in a power of 10
    var case9_a_mojo = Decimal128("10")
    var case9_b_mojo = Decimal128("0.001")
    var case9_a_py = pydecimal.Decimal128("10")
    var case9_b_py = pydecimal.Decimal128("0.001")
    run_benchmark(
        "Division resulting in power of 10",
        case9_a_mojo,
        case9_b_mojo,
        case9_a_py,
        case9_b_py,
        iterations,
        log_file,
    )

    # Case 10: Division of very large by very large
    var case10_a_mojo = Decimal128("9" * 20)  # 20 nines
    var case10_b_mojo = Decimal128("9" * 10)  # 10 nines
    var case10_a_py = pydecimal.Decimal128("9" * 20)
    var case10_b_py = pydecimal.Decimal128("9" * 10)
    run_benchmark(
        "Division of very large numbers",
        case10_a_mojo,
        case10_b_mojo,
        case10_a_py,
        case10_b_py,
        iterations,
        log_file,
    )

    # Display summary
    log_print("\n=== Division Benchmark Summary ===", log_file)
    log_print("Benchmarked:      10 different division cases", log_file)
    log_print(
        "Each case ran:    " + String(iterations) + " iterations", log_file
    )
    log_print(
        "Performance:      See detailed results above for each case", log_file
    )

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
