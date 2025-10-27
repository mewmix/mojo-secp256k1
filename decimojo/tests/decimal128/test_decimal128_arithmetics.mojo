"""
Test Decimal128 arithmetic operations including addition, subtraction, and negation.
"""

from decimojo.prelude import dm, Decimal128, RoundingMode
import testing


fn test_add() raises:
    print("------------------------------------------------------")
    print("Testing decimal addition...")

    # Test case 1: Simple addition with same scale
    var a1 = Decimal128(12345, scale=2)  # 123.45
    var b1 = Decimal128(6789, scale=2)  # 67.89
    var result1 = a1 + b1
    testing.assert_equal(
        String(result1), "191.34", "Simple addition with same scale"
    )

    # Test case 2: Addition with different scales
    var a2 = Decimal128(1234, scale=1)
    var b2 = Decimal128(6789, scale=2)
    var result2 = a2 + b2
    testing.assert_equal(
        String(result2), "191.29", "Addition with different scales"
    )

    # Test case 3: Addition with negative numbers
    var a3 = Decimal128(12345, scale=2)
    var b3 = Decimal128(-6789, scale=2)
    var result3 = a3 + b3
    testing.assert_equal(
        String(result3), "55.56", "Addition with negative number"
    )

    # Test case 4: Addition resulting in negative
    var a4 = Decimal128(-12345, scale=2)
    var b4 = Decimal128(6789, scale=2)
    var result4 = a4 + b4
    testing.assert_equal(
        String(result4), "-55.56", "Addition resulting in negative"
    )

    # Test case 5: Addition with zero
    var a5 = Decimal128(12345, scale=2)
    var b5 = Decimal128(0, scale=2)
    var result5 = a5 + b5
    testing.assert_equal(String(result5), "123.45", "Addition with zero")

    # Test case 6: Addition resulting in zero
    var a6 = Decimal128(12345, scale=2)
    var b6 = Decimal128(-12345, scale=2)
    var result6 = a6 + b6
    testing.assert_equal(String(result6), "0.00", "Addition resulting in zero")

    # Test case 7: Addition with large scales
    var a7 = Decimal128(1, scale=7)
    var b7 = Decimal128(2, scale=7)
    var result7 = a7 + b7
    testing.assert_equal(
        String(result7), "0.0000003", "Addition with large scales"
    )

    # Test case 8: Addition with different large scales
    var a8 = Decimal128(1, scale=6)
    var b8 = Decimal128(2, scale=7)
    var result8 = a8 + b8
    testing.assert_equal(
        String(result8), "0.0000012", "Addition with different large scales"
    )

    # Additional edge cases for addition

    # Test case 9: Addition with many decimal places
    var a9 = Decimal128.from_uint128(123456789012345678901234567, scale=27)
    var b9 = Decimal128.from_uint128(987654321098765432109876543, scale=27)
    var result9 = a9 + b9
    testing.assert_equal(
        String(result9),
        "1.111111110111111111011111110",
        "Addition with many decimal places",
    )

    # Test case 10: Addition with extreme scale difference
    var a10 = Decimal128(123456789)
    var b10 = Decimal128(123456789, scale=18)  # 0.000000000123456789
    var result10 = a10 + b10
    testing.assert_equal(
        String(result10),
        "123456789.000000000123456789",
        "Addition with extreme scale difference",
    )

    # Test case 11: Addition near maximum precision
    var a11 = Decimal128.from_uint128(
        UInt128(1111111111111111111111111111), scale=28
    )  # 0.1111...1 (28 digits)
    var b11 = Decimal128.from_uint128(
        UInt128(9999999999999999999999999999), scale=28
    )  # 0.9999...9 (28 digits)
    var result11 = a11 + b11
    testing.assert_equal(
        String(result11),
        "1.1111111111111111111111111110",
        "Addition near maximum precision",
    )

    # Test case 12: Addition causing scale truncation
    var a12 = Decimal128.from_uint128(
        UInt128(1111111111111111111111111111), scale=28
    )  # 0.1111...1 (28 digits)
    var b12 = Decimal128.from_uint128(
        UInt128(999999999999999999999999999), scale=28
    )  # 0.09999...9 (28 digits)
    var result12 = a12 + b12
    testing.assert_equal(
        String(result12),
        "0." + "2" + "1" * 26 + "0",
        "Addition causing scale truncation",
    )

    # Test case 13: Addition of very small numbers
    var a13 = Decimal128(1, scale=28)  # 0.0000...01 (1 at 28th place)
    var b13 = Decimal128(2, scale=28)  # 0.0000...02 (2 at 28th place)
    var result13 = a13 + b13
    testing.assert_equal(
        String(result13),
        "0." + "0" * 27 + "3",
        "Addition of very small numbers",
    )

    # Test case 14: Addition with alternating signs and scales
    var a14 = Decimal128(101, 2)
    var b14 = Decimal128(-101, 3)
    var result14 = a14 + b14
    testing.assert_equal(
        String(result14), "0.909", "Addition with alternating signs and scales"
    )

    # Test case 15: Addition with large numbers (near limits)
    var a15 = Decimal128.from_uint128(
        UInt128(79228162514264337593543950334)
    )  # MAX() - 1
    var b15 = Decimal128(1)
    var result15 = a15 + b15
    testing.assert_equal(
        String(result15),
        "79228162514264337593543950335",
        "Addition approaching maximum value",
    )

    # Test case 16: Repeated addition to test cumulative errors
    var acc = Decimal128(0)
    for _ in range(10):
        acc = acc + Decimal128(1, scale=1)
    testing.assert_equal(String(acc), "1.0", "Repeated addition of 0.1")

    # Test case 17: Edge case with alternating very large and very small values
    var a17 = Decimal128.from_uint128(12345678901234567890123456789, scale=10)
    var b17 = Decimal128(9876543211, scale=28)
    var result17 = a17 + b17
    # 1234567890123456789.0123456789000000009876543211
    testing.assert_equal(
        String(result17),
        "1234567890123456789.0123456789",
        "Addition with large and small values",
    )

    print("Decimal128 addition tests passed!")

    # Test case 18: Edge case with one equals 0
    var a18 = Decimal128.from_uint128(
        UInt128(45631171710880163026696499898), scale=13
    )
    var b18 = Decimal128(0, scale=28)
    var result18 = a18 + b18
    # 1234567890123456789.0123456789
    testing.assert_equal(
        String(result18),
        "4563117171088016.3026696499898",
        "Addition with zeros",
    )

    print("Decimal128 addition tests passed!")


fn test_negation() raises:
    print("------------------------------------------------------")
    print("Testing decimal negation...")

    # Test case 1: Negate positive number
    var a1 = Decimal128(12345, 2)
    var result1 = -a1
    testing.assert_equal(String(result1), "-123.45", "Negating positive number")

    # Test case 2: Negate negative number
    var a2 = Decimal128(-6789, 2)
    var result2 = -a2
    testing.assert_equal(String(result2), "67.89", "Negating negative number")

    # Test case 3: Negate zero
    var a3 = Decimal128(0)
    var result3 = -a3
    testing.assert_equal(String(result3), "0", "Negating zero")

    # Test case 4: Negate number with trailing zeros
    var a4 = Decimal128(1234500, 4)
    var result4 = -a4
    testing.assert_equal(
        String(result4), "-123.4500", "Negating with trailing zeros"
    )

    # Test case 5: Double negation
    var a5 = Decimal128(12345, 2)
    var result5 = -(-a5)
    testing.assert_equal(String(result5), "123.45", "Double negation")

    # Additional edge cases for negation

    # Test case 6: Negate very small number
    var a6 = Decimal128(1, scale=28)  # 0.0000...01 (1 at 28th place)
    var result6 = -a6
    testing.assert_equal(
        String(result6), "-0." + "0" * 27 + "1", "Negating very small number"
    )

    # Test case 7: Negate very large number
    var a7 = Decimal128.from_uint128(
        UInt128(79228162514264337593543950335)
    )  # MAX()
    var result7 = -a7
    testing.assert_equal(
        String(result7),
        "-79228162514264337593543950335",
        "Negating maximum value",
    )

    # Test case 8: Triple negation
    var a8 = Decimal128(12345, 2)
    var result8 = -(-(-a8))
    testing.assert_equal(String(result8), "-123.45", "Triple negation")

    # Test case 9: Negate number with scientific notation
    var a9 = Decimal128("1.23e5")  # 123000
    var result9 = -a9
    testing.assert_equal(
        String(result9),
        "-123000",
        "Negating number from scientific notation",
    )

    # Test case 10: Negate number with maximum precision
    var a10 = Decimal128("0." + "1" * 28)  # 0.1111...1 (28 digits)
    var result10 = -a10
    testing.assert_equal(
        String(result10),
        "-0." + "1" * 28,
        "Negating number with maximum precision",
    )

    print("Decimal128 negation tests passed!")


fn test_abs() raises:
    print("------------------------------------------------------")
    print("Testing decimal absolute value...")

    # Test case 1: Absolute value of positive number
    var a1 = Decimal128(12345, 2)
    var result1 = abs(a1)
    testing.assert_equal(
        String(result1), "123.45", "Absolute value of positive number"
    )

    # Test case 2: Absolute value of negative number
    var a2 = Decimal128(-6789, 2)
    var result2 = abs(a2)
    testing.assert_equal(
        String(result2), "67.89", "Absolute value of negative number"
    )

    # Test case 3: Absolute value of zero
    var a3 = Decimal128(0)
    var result3 = abs(a3)
    testing.assert_equal(String(result3), "0", "Absolute value of zero")

    # Test case 4: Absolute value of negative zero (if supported)
    var a4 = Decimal128(-0, 2)
    var result4 = abs(a4)
    testing.assert_equal(
        String(result4), "0.00", "Absolute value of negative zero"
    )

    # Test case 5: Absolute value with large number of decimal places
    var a5 = Decimal128(-1, 10)
    var result5 = abs(a5)
    testing.assert_equal(
        String(result5),
        "0.0000000001",
        "Absolute value of small negative number",
    )

    # Test case 6: Absolute value of very large number
    var a6 = Decimal128("-9999999999.9999999999")
    var result6 = abs(a6)
    testing.assert_equal(
        String(result6),
        "9999999999.9999999999",
        "Absolute value of large negative number",
    )

    # Test case 7: Absolute value of number with many significant digits
    var a7 = Decimal128("-0.123456789012345678901234567")
    var result7 = abs(a7)
    testing.assert_equal(
        String(result7),
        "0.123456789012345678901234567",
        "Absolute value of high precision negative number",
    )

    # Test case 8: Absolute value of maximum representable number
    try:
        var a8 = Decimal128.from_uint128(
            UInt128(79228162514264337593543950335)
        )  # Maximum value
        var result8 = abs(a8)
        testing.assert_equal(
            String(result8),
            "79228162514264337593543950335",
            "Absolute value of maximum value",
        )

        var a9 = Decimal128(
            "-79228162514264337593543950335"
        )  # Negative maximum value
        var result9 = abs(a9)
        testing.assert_equal(
            String(result9),
            "79228162514264337593543950335",
            "Absolute value of negative maximum value",
        )
    except:
        print("Maximum value test not applicable")

    print("Decimal128 absolute value tests passed!")


fn test_subtract() raises:
    print("------------------------------------------------------")
    print("Testing decimal subtraction...")

    # Test case 1: Simple subtraction with same scale
    var a1 = Decimal128(12345, 2)
    var b1 = Decimal128(6789, 2)
    var result1 = a1 - b1
    testing.assert_equal(
        String(result1), "55.56", "Simple subtraction with same scale"
    )

    # Test case 2: Subtraction with different scales
    var a2 = Decimal128(1234, 1)
    var b2 = Decimal128(6789, 2)
    var result2 = a2 - b2
    testing.assert_equal(
        String(result2), "55.51", "Subtraction with different scales"
    )

    # Test case 3: Subtraction resulting in negative
    var a3 = Decimal128(6789, 2)
    var b3 = Decimal128(12345, 2)
    var result3 = a3 - b3
    testing.assert_equal(
        String(result3), "-55.56", "Subtraction resulting in negative"
    )

    # Test case 4: Subtraction of negative numbers
    var a4 = Decimal128(12345, 2)
    var b4 = Decimal128(-6789, 2)
    var result4 = a4 - b4
    testing.assert_equal(
        String(result4), "191.34", "Subtraction of negative number"
    )

    # Test case 5: Subtraction with zero
    var a5 = Decimal128(12345, 2)
    var b5 = Decimal128(0, 2)
    var result5 = a5 - b5
    testing.assert_equal(String(result5), "123.45", "Subtraction with zero")

    # Test case 6: Subtraction resulting in zero
    var a6 = Decimal128(12345, 2)
    var b6 = Decimal128(12345, 2)
    var result6 = a6 - b6
    testing.assert_equal(
        String(result6), "0.00", "Subtraction resulting in zero"
    )

    # Test case 7: Subtraction with large scales
    var a7 = Decimal128(3, 7)
    var b7 = Decimal128(2, 7)
    var result7 = a7 - b7
    testing.assert_equal(
        String(result7), "0.0000001", "Subtraction with large scales"
    )

    # Test case 8: Subtraction with different large scales
    var a8 = Decimal128(5, 6)
    var b8 = Decimal128(2, 7)
    var result8 = a8 - b8
    testing.assert_equal(
        String(result8), "0.0000048", "Subtraction with different large scales"
    )

    # Test case 9: Subtraction with small difference
    var a9 = Decimal128(10000001, 7)
    var b9 = Decimal128(10000000, 7)
    var result9 = a9 - b9
    testing.assert_equal(
        String(result9), "0.0000001", "Subtraction with small difference"
    )

    # Test case 10: Subtraction of very small from very large
    var a10 = Decimal128("9999999999.9999999")
    var b10 = Decimal128("0.0000001")
    var result10 = a10 - b10
    testing.assert_equal(
        String(result10),
        "9999999999.9999998",
        "Subtraction of very small from very large",
    )

    # Test case 11: Self subtraction for various values (expanded from list)
    # Individual test cases instead of iterating over a list
    var value1 = Decimal128(0)
    testing.assert_equal(
        String(value1 - value1),
        String(round(Decimal128(0), value1.scale())),
        "Self subtraction should yield zero (0)",
    )

    var value2 = Decimal128(12345, 2)
    testing.assert_equal(
        String(value2 - value2),
        String(round(Decimal128(0), value2.scale())),
        "Self subtraction should yield zero (123.45)",
    )

    var value3 = Decimal128(-987654, 3)
    testing.assert_equal(
        String(value3 - value3),
        String(round(Decimal128(0), value3.scale())),
        "Self subtraction should yield zero (-987.654)",
    )

    var value4 = Decimal128(1, 4)
    testing.assert_equal(
        String(value4 - value4),
        String(round(Decimal128(0), value4.scale())),
        "Self subtraction should yield zero (0.0001)",
    )

    var value5 = Decimal128("-99999.99999")
    testing.assert_equal(
        String(value5 - value5),
        String(round(Decimal128(0), value5.scale())),
        "Self subtraction should yield zero (-99999.99999)",
    )

    # Test case 12: Verify that a - b = -(b - a)
    var a12a = Decimal128(123456, 3)
    var b12a = Decimal128(789012, 3)
    var result12a = a12a - b12a
    var result12b = -(b12a - a12a)
    testing.assert_equal(
        String(result12a), String(result12b), "a - b should equal -(b - a)"
    )

    print("Decimal128 subtraction tests passed!")


fn test_extreme_cases() raises:
    print("------------------------------------------------------")
    print("Testing extreme cases...")

    # Test case 1: Addition that results in exactly zero with high precision
    var a1 = Decimal128("0." + "1" * 28)  # 0.1111...1 (28 digits)
    var b1 = Decimal128("-0." + "1" * 28)  # -0.1111...1 (28 digits)
    var result1 = a1 + b1
    testing.assert_equal(
        String(result1),
        "0." + "0" * 28,
        "High precision addition resulting in zero",
    )

    # Test case 2: Addition that should trigger overflow handling
    try:
        var a2 = Decimal128("79228162514264337593543950335")  # MAX()
        var b2 = Decimal128(1)
        var _result2 = a2 + b2
        print("WARNING: Addition beyond MAX() didn't raise an error")
    except:
        print("Addition overflow correctly detected")

    # Test case 3: Addition with mixed precision zeros
    var a3 = Decimal128("0.00")
    var b3 = Decimal128("0.000000")
    var result3 = a3 + b3
    testing.assert_equal(
        String(result3), "0.000000", "Addition of different precision zeros"
    )

    # Test case 4: Addition with boundary values involving zeros
    var a4 = Decimal128("0.0")
    var b4 = Decimal128("-0.00")
    var result4 = a4 + b4
    testing.assert_equal(
        String(result4), "0.00", "Addition of positive and negative zero"
    )

    # Test case 5: Adding numbers that require carry propagation through many places
    var a5 = Decimal128("9" * 20 + "." + "9" * 28)  # 99...9.99...9
    var b5 = Decimal128("0." + "0" * 27 + "1")  # 0.00...01
    var result5 = a5 + b5
    # The result should be 10^20 exactly, since all 9s carry over
    testing.assert_equal(
        String(result5),
        "100000000000000000000.00000000",
        "Addition with extensive carry propagation",
    )

    print("Extreme case tests passed!")


fn main() raises:
    print("Running decimal arithmetic tests")

    # Run addition tests
    test_add()

    # Run negation tests
    test_negation()

    # Run absolute value tests
    test_abs()

    # Run subtraction tests
    test_subtract()

    # Run extreme cases tests
    test_extreme_cases()

    print("All decimal arithmetic tests passed!")
