# ===----------------------------------------------------------------------=== #
# Copyright 2025 Yuhao Zhu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

"""
Implements functions for mathematical operations on BigDecimal objects.
"""

import math

from decimojo.rounding_mode import RoundingMode

# ===----------------------------------------------------------------------=== #
# Arithmetic operations on BigDecimal objects
# add(x1, x2)
# subtract(x1, x2)
# multiply(x1, x2)
# true_divide(x1, x2, precision)
# true_divide_inexact(x1, x2, number_of_significant_digits)
# ===----------------------------------------------------------------------=== #


fn add(x1: BigDecimal, x2: BigDecimal) raises -> BigDecimal:
    """Returns the sum of two numbers.

    Args:
        x1: The first operand.
        x2: The second operand.

    Returns:
        The sum of x1 and x2.

    Notes:

    Rules for addition:
    - This function always return the exact result of the addition.
    - The result's scale is the maximum of the two operands' scales.
    - The result's sign is determined by the signs of the operands.
    """
    var max_scale = max(x1.scale, x2.scale)
    var scale_factor1 = (max_scale - x1.scale) if x1.scale < max_scale else 0
    var scale_factor2 = (max_scale - x2.scale) if x2.scale < max_scale else 0

    # Handle zero operands as special cases for efficiency
    if x1.coefficient.is_zero():
        if x2.coefficient.is_zero():
            return BigDecimal(
                coefficient=BigUInt.ZERO,
                scale=max_scale,
                sign=False,
            )
        else:
            return x2.extend_precision(scale_factor2)
    if x2.coefficient.is_zero():
        return x1.extend_precision(scale_factor1)

    # Scale coefficients to match
    var coef1 = x1.coefficient.multiply_by_power_of_ten(scale_factor1)
    var coef2 = x2.coefficient.multiply_by_power_of_ten(scale_factor2)

    # Handle addition based on signs
    if x1.sign == x2.sign:
        # Same sign: Add coefficients, keep sign
        coef1 += coef2
        return BigDecimal(coefficient=coef1^, scale=max_scale, sign=x1.sign)
    # Different signs: Subtract smaller coefficient from larger
    if coef1 > coef2:
        # |x1| > |x2|, result sign is x1's sign
        coef1 -= coef2
        return BigDecimal(coefficient=coef1^, scale=max_scale, sign=x1.sign)
    elif coef2 > coef1:
        # |x2| > |x1|, result sign is x2's sign
        coef2 -= coef1
        return BigDecimal(coefficient=coef2^, scale=max_scale, sign=x2.sign)
    else:
        # |x1| == |x2|, signs differ, result is 0
        return BigDecimal(coefficient=BigUInt.ZERO, scale=max_scale, sign=False)


fn subtract(x1: BigDecimal, x2: BigDecimal) raises -> BigDecimal:
    """Returns the difference of two numbers.

    Args:
        x1: The first operand (minuend).
        x2: The second operand (subtrahend).

    Returns:
        The difference of x1 and x2 (x1 - x2).

    Notes:

    - This function always return the exact result of the subtraction.
    - The result's scale is the maximum of the two operands' scales.
    - The result's sign is determined by the signs of the operands.
    """

    var max_scale = max(x1.scale, x2.scale)
    var scale_factor1 = (max_scale - x1.scale) if x1.scale < max_scale else 0
    var scale_factor2 = (max_scale - x2.scale) if x2.scale < max_scale else 0

    # Handle zero operands as special cases for efficiency
    if x2.coefficient.is_zero():
        if x1.coefficient.is_zero():
            return BigDecimal(
                coefficient=BigUInt.ZERO,
                scale=max_scale,
                sign=False,
            )
        else:
            return x1.extend_precision(scale_factor1)
    if x1.coefficient.is_zero():
        var result = x2.extend_precision(scale_factor2)
        result.sign = not result.sign
        return result^

    # Scale coefficients to match
    var coef1 = x1.coefficient.multiply_by_power_of_ten(scale_factor1)
    var coef2 = x2.coefficient.multiply_by_power_of_ten(scale_factor2)

    # Handle subtraction based on signs
    if x1.sign != x2.sign:
        # Different signs: x1 - (-x2) = x1 + x2, or (-x1) - x2 = -(x1 + x2)
        coef1 += coef2
        return BigDecimal(coefficient=coef1^, scale=max_scale, sign=x1.sign)

    # Same signs: Must perform actual subtraction
    if coef1 > coef2:
        # |x1| > |x2|, result sign is x1's sign
        coef1 -= coef2
        return BigDecimal(coefficient=coef1^, scale=max_scale, sign=x1.sign)
    elif coef2 > coef1:
        # |x1| < |x2|, result sign is opposite of x1's sign
        coef2 -= coef1
        return BigDecimal(coefficient=coef2^, scale=max_scale, sign=not x1.sign)
    else:
        # |x1| == |x2|, result is 0
        return BigDecimal(coefficient=BigUInt.ZERO, scale=max_scale, sign=False)


fn multiply(x1: BigDecimal, x2: BigDecimal) -> BigDecimal:
    """Returns the product of two numbers.

    Args:
        x1: The first operand (multiplicand).
        x2: The second operand (multiplier).

    Returns:
        The product of x1 and x2.

    Notes:

    - This function always returns the exact result of the multiplication.
    - The result's scale is the sum of the two operands' scales (except for zero).
    - The result's sign follows the standard sign rules for multiplication.
    """
    # Handle zero operands as special cases for efficiency
    if x1.coefficient.is_zero() or x2.coefficient.is_zero():
        return BigDecimal(
            coefficient=BigUInt.ZERO,
            scale=x1.scale + x2.scale,
            sign=x1.sign != x2.sign,
        )

    return BigDecimal(
        coefficient=x1.coefficient * x2.coefficient,
        scale=x1.scale + x2.scale,
        sign=x1.sign != x2.sign,
    )


fn true_divide(
    x: BigDecimal, y: BigDecimal, precision: Int
) raises -> BigDecimal:
    """Returns the quotient of two numbers with specified precision.

    Args:
        x: The first operand (dividend).
        y: The second operand (divisor).
        precision: The number of significant digits in the result.

    Returns:
        The quotient of x and y, with precision up to `precision`
        significant digits.

    Notes:

    - If the coefficients can be divided exactly, the number of digits after
        the decimal point is the difference of the scales of the two operands.
    - If the coefficients cannot be divided exactly, the number of digits after
        the decimal point is precision.
    - If the division is not exact, the number of digits after the decimal
        point is calcuated to precision + BUFFER_DIGITS, and the result is
        rounded to precision according to the specified rules.
    """
    # Check for division by zero
    if y.coefficient.is_zero():
        raise Error("bigdecimal.arithmetics.true_divide(): Division by zero")

    # Handle dividend of zero
    if x.coefficient.is_zero():
        return BigDecimal(
            coefficient=BigUInt.ZERO,
            scale=x.scale - y.scale,
            sign=x.sign != y.sign,
        )

    # For other cases, we use `true_divide_general()` to handle the division
    # Note that this functiona already considers extra buffer digits
    return true_divide_general(x, y, precision)


fn true_divide_fast(
    x: BigDecimal, y: BigDecimal, minimum_precision: Int
) raises -> BigDecimal:
    """Returns the quotient of two numbers.

    Args:
        x: The first operand (dividend).
        y: The second operand (divisor).
        minimum_precision: The minimum number of significant digits in the
            result. Should be greater than 0.

    Returns:
        The quotient of x and y with at least `minimum_precision`
        significant digits.

    Notes:

    This function conduct a quick division that:
    (1) does not round the result to the specified precision.
    (2) does not check the exact division nor remove extra trailing zeros.
    """

    # Yuhao Zhu:
    # x = a * 10*(-m)
    # y = b * 10*(-n)
    # Let s = extra digits to ensure precision
    # x / y = x * 10^s / y / 10^s = (a * 10^s // b) * 10*(-(m + s - n))
    # We need to ensure that a * 10^s // b has more significant digits than p.
    # A quicker way is to add whole empty words to the dividend.
    # Let n_diff = len(a.words) - len(b.words).
    # We add ceil(precision // 9) + 1 - n_diff empty words to the dividend.
    # This ensures that we always have at least 9 extra digits in the dividend.

    debug_assert[assert_mode="none"](
        minimum_precision > 0,
        "Minimum precision should be greater than 0",
    )

    var diff_n_words = len(x.coefficient.words) - len(y.coefficient.words)
    var extra_words = math.ceildiv(minimum_precision, 9) + 2 - diff_n_words
    var extra_digits = extra_words * 9

    var coef_x: BigUInt
    if extra_words > 0:
        coef_x = decimojo.biguint.arithmetics.multiply_by_power_of_billion(
            x.coefficient, extra_words
        )
    elif extra_words < 0:
        coef_x = decimojo.biguint.arithmetics.floor_divide_by_power_of_billion(
            x.coefficient, -extra_words * 9
        )
    else:
        coef_x = x.coefficient

    var coef = coef_x // y.coefficient
    var scale = x.scale + extra_digits - y.scale
    return BigDecimal(
        coefficient=coef^,
        scale=scale,
        sign=x.sign != y.sign,
    )


fn true_divide_general(
    x: BigDecimal, y: BigDecimal, precision: Int
) raises -> BigDecimal:
    """Returns the quotient of two numbers with the specified precision.

    Args:
        x: The first operand (dividend).
        y: The second operand (divisor).
        precision: The minimum number of significant digits in the
            result. Should be greater than 0.

    Returns:
        The quotient of x and y with the specified precision.

    Notes:

    This function conduct a division that:
    (1) rounds the result to the specified precision,
    (2) checks the exact division and remove extra trailing zeros.
    """

    # Yuhao Zhu:
    # x = a * 10*(-m)
    # y = b * 10*(-n)
    # Let s = extra digits to ensure precision
    # x / y = x * 10^s / y / 10^s = (a * 10^s // b) * 10*(-(m + s - n))
    # We need to ensure that a * 10^s // b has more significant digits than p.
    # A quicker way is to add whole empty words to the dividend.
    # Let n_diff = len(a.words) - len(b.words).
    # We add ceil(precision // 9) + 1 + max(-n_diff, 0) words to the dividend.
    # This ensures that we always have at least 9 extra digits in the dividend.
    # We take max(-n_diff, 0) because we need to check the exact division.

    debug_assert[assert_mode="none"](
        precision > 0,
        "Precision should be greater than 0",
    )

    var diff_n_words = len(x.coefficient.words) - len(y.coefficient.words)
    var extra_words = math.ceildiv(precision, 9) + 2
    if diff_n_words < 0:
        extra_words -= diff_n_words  # diff_n_words is negative, so we add words
    var extra_digits = extra_words * 9

    var coef_x: BigUInt
    if extra_words > 0:
        coef_x = decimojo.biguint.arithmetics.multiply_by_power_of_billion(
            x.coefficient, extra_words
        )
    else:
        coef_x = x.coefficient

    var coef = coef_x // y.coefficient
    if coef * y.coefficient == coef_x:
        # The division is exact, so we need to remove the extra trailing zeros
        # so that the final scale is at least (x.scale - y.scale).
        # If x.scale - y.scale < 0, we can safely remove all trailing zeros.
        # Otherwise, we can remove at most extra digits added.
        var num_digits_to_remove = min(
            extra_digits, coef.number_of_trailing_zeros()
        )
        # TODO: Make a in-place version of this
        coef = decimojo.biguint.arithmetics.floor_divide_by_power_of_ten(
            coef, num_digits_to_remove
        )
        extra_digits -= num_digits_to_remove

    var scale = x.scale + extra_digits - y.scale
    var result = BigDecimal(
        coefficient=coef^,
        scale=scale,
        sign=x.sign != y.sign,
    )
    result.round_to_precision(
        precision,
        RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )
    return result^


fn true_divide_inexact(
    x1: BigDecimal, x2: BigDecimal, number_of_significant_digits: Int
) raises -> BigDecimal:
    """Returns the quotient of two numbers with number of significant digits.
    This function is a faster version of true_divide, but it does not
    return the exact result of the division since no extra buffer digits are
    added to the dividend during calculation.
    It is recommended to use this function when you already know the dividend
    has enough digits to produce a result with the desired precision. Then
    use rounding to get the result with the desired precision.

    Args:
        x1: The first operand (dividend).
        x2: The second operand (divisor).
        number_of_significant_digits: The number of significant digits in the
            result.

    Returns:
        The quotient of x1 and x2.
    """

    # Check for division by zero
    if x2.coefficient.is_zero():
        raise Error("Division by zero")

    # Handle dividend of zero
    if x1.coefficient.is_zero():
        return BigDecimal(
            coefficient=BigUInt.ZERO,
            scale=number_of_significant_digits,
            sign=x1.sign != x2.sign,
        )

    # First estimate the number of significant digits needed in the dividend
    # to produce a result with precision significant digits
    var x1_digits = x1.coefficient.number_of_digits()
    var x2_digits = x2.coefficient.number_of_digits()

    # Calculate how many digits we need in the dividend
    # We want: x1_digits - x2_digits >= mininum_precision
    var buffer_digits = number_of_significant_digits - (x1_digits - x2_digits)
    buffer_digits = max(0, buffer_digits)

    # Scale up the dividend to ensure sufficient precision
    var scaled_x1 = x1.coefficient
    if buffer_digits > 0:
        scaled_x1.multiply_inplace_by_power_of_ten(buffer_digits)

    # Perform division
    var quotient: BigUInt = scaled_x1 // x2.coefficient
    var result_scale = buffer_digits + x1.scale - x2.scale

    var result_digits = quotient.number_of_digits()
    if result_digits > number_of_significant_digits:
        var digits_to_remove = result_digits - number_of_significant_digits
        quotient = quotient.remove_trailing_digits_with_rounding(
            digits_to_remove,
            RoundingMode.ROUND_DOWN,
            remove_extra_digit_due_to_rounding=False,
        )
        # Adjust the scale accordingly
        result_scale -= digits_to_remove

    return BigDecimal(
        coefficient=quotient^,
        scale=result_scale,
        sign=x1.sign != x2.sign,
    )


fn truncate_divide(x1: BigDecimal, x2: BigDecimal) raises -> BigDecimal:
    """Returns the quotient of two numbers truncated to zeros.

    Args:
        x1: The first operand (dividend).
        x2: The second operand (divisor).

    Returns:
        The quotient of x1 and x2, truncated to zeros.

    Raises:
        Error: If division by zero is attempted.

    Notes:
        This function performs integer division that truncates toward zero.
        For example: 7//4 = 1, -7//4 = -1, 7//(-4) = -1, (-7)//(-4) = 1.
    """
    # Check for division by zero
    if x2.coefficient.is_zero():
        raise Error("Division by zero")

    # Handle dividend of zero
    if x1.coefficient.is_zero():
        return BigDecimal(BigUInt.ZERO, 0, False)

    # Calculate adjusted scales to align decimal points
    var scale_diff = x1.scale - x2.scale

    # If scale_diff is positive, we need to scale up the dividend
    # If scale_diff is negative, we need to scale up the divisor
    if scale_diff > 0:
        var divisor = x2.coefficient.multiply_by_power_of_ten(scale_diff)
        var quotient = x1.coefficient.truncate_divide(divisor)
        return BigDecimal(quotient^, 0, x1.sign != x2.sign)

    else:  # scale_diff < 0
        var dividend = x1.coefficient.multiply_by_power_of_ten(-scale_diff)
        var quotient = dividend.truncate_divide(x2.coefficient)
        return BigDecimal(quotient^, 0, x1.sign != x2.sign)


fn truncate_modulo(
    x1: BigDecimal, x2: BigDecimal, precision: Int
) raises -> BigDecimal:
    """Returns the trucated modulo of two numbers.

    Args:
        x1: The first operand (dividend).
        x2: The second operand (divisor).
        precision: The number of significant digits in the result.

    Returns:
        The truncated modulo of x1 and x2.

    Raises:
        Error: If division by zero is attempted.
    """
    # Check for division by zero
    if x2.coefficient.is_zero():
        raise Error("Division by zero")

    return subtract(
        x1,
        multiply(
            truncate_divide(x1, x2),
            x2,
        ),
    )
