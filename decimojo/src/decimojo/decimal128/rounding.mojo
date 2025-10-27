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
#
# Implements basic object methods for the Decimal128 type
# which supports correctly-rounded, fixed-point arithmetic.
#
# ===----------------------------------------------------------------------=== #
#
# List of functions in this module:
#
# round(x: Decimal128, places: Int, mode: RoundingMode): Rounds x to specified decimal places
#
# ===----------------------------------------------------------------------=== #

"""
Implements functions for mathematical operations on Decimal128 objects.
"""

import testing

from decimojo.decimal128.decimal128 import Decimal128
from decimojo.rounding_mode import RoundingMode
import decimojo.decimal128.utility

# ===------------------------------------------------------------------------===#
# Rounding
# ===------------------------------------------------------------------------===#


fn round(
    number: Decimal128,
    ndigits: Int = 0,
    rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
) raises -> Decimal128:
    """
    Rounds the Decimal128 to the specified number of decimal places.

    Args:
        number: The Decimal128 to round.
        ndigits: Number of decimal places to round to.
            Defaults to 0.
        rounding_mode: Rounding mode to use.
            Defaults to ROUND_HALF_EVEN (banker's rounding).

    Returns:
        A new Decimal128 rounded to the specified number of decimal places.
    """

    # Number of decimal places of the number is equal to the scale of the number
    var x_scale = number.scale()
    # `ndigits` is equal to the scale of the final number
    var scale_diff = ndigits - x_scale

    # CASE: If already at the desired scale
    # Return a copy directly
    # 情况一：如果已经在所需的标度上, 直接返回其副本
    #
    # round(Decimal128("123.456"), 3) -> Decimal128("123.456")
    if scale_diff == 0:
        return number

    var x_coef = number.coefficient()
    var ndigits_of_x = decimojo.decimal128.utility.number_of_digits(x_coef)

    # CASE: If ndigits is larger than the current scale
    # Scale up the coefficient of the number to the desired scale
    # If scaling up causes an overflow, raise an error
    # 情况二：如果ndigits大于当前标度, 将係數放大
    #
    # Examples:
    # round(Decimal128("123.456"), 5) -> Decimal128("123.45600")
    # round(Decimal128("123.456"), 29) -> Error

    if scale_diff > 0:
        # If the digits of result > 29, directly raise an error
        if ndigits_of_x + scale_diff > Decimal128.MAX_NUM_DIGITS:
            raise Error(
                String(
                    "Error in `round()`: `ndigits = {}` causes the number of"
                    " digits in the significant figures of the result (={})"
                    " exceeds the maximum capacity (={})."
                ).format(
                    ndigits,
                    ndigits_of_x + scale_diff,
                    Decimal128.MAX_NUM_DIGITS,
                )
            )

        # If the digits of result <= 29, calculate the result by scaling up
        else:
            var res_coef = x_coef * UInt128(10) ** scale_diff

            # If the digits of result == 29, but the result >= 2^96, raise an error
            if (ndigits_of_x + scale_diff == Decimal128.MAX_NUM_DIGITS) and (
                res_coef > Decimal128.MAX_AS_UINT128
            ):
                raise Error(
                    String(
                        "Error in `round()`: `ndigits = {}` causes the"
                        " significant digits of the result (={}) exceeds the"
                        " maximum capacity (={})."
                    ).format(ndigits, res_coef, Decimal128.MAX_AS_UINT128)
                )

            # In other cases, return the result
            else:
                return Decimal128.from_uint128(
                    res_coef, scale=ndigits, sign=number.is_negative()
                )

    # CASE: If ndigits is smaller than the current scale
    # Scale down the coefficient of the number to the desired scale and round
    # 情况三：如果ndigits小于当前标度, 将係數縮小, 然后捨去
    #
    # If `ndigits` is negative, the result need to be scaled up again.
    #
    # Examples:
    # round(Decimal128("987.654321"), 3) -> Decimal128("987.654")
    # round(Decimal128("987.654321"), -2) -> Decimal128("1000")
    # round(Decimal128("987.654321"), -3) -> Decimal128("1000")
    # round(Decimal128("987.654321"), -4) -> Decimal128("0")

    else:
        # scale_diff < 0
        # Calculate the number of digits to keep
        var ndigits_to_keep = ndigits_of_x + scale_diff

        # Keep the first `ndigits_to_keep` digits with specified rounding mode
        var res_coef = decimojo.decimal128.utility.round_to_keep_first_n_digits(
            x_coef, ndigits=ndigits_to_keep, rounding_mode=rounding_mode
        )

        if ndigits >= 0:
            return Decimal128.from_uint128(
                res_coef, scale=ndigits, sign=number.is_negative()
            )

        # if `ndigits` is negative and `ndigits_to_keep` >= 0, scale up the result
        elif ndigits_to_keep >= 0:
            res_coef *= UInt128(10) ** (-ndigits)
            return Decimal128.from_uint128(
                res_coef, scale=0, sign=number.is_negative()
            )

        # if `ndigits` is negative and `ndigits_to_keep` < 0, return 0
        else:
            return Decimal128.ZERO()


fn quantize(
    value: Decimal128,
    exp: Decimal128,
    rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
) raises -> Decimal128:
    """Rounds the value according to the exponent of the second operand.
    Unlike `round()`, the scale is determined by the scale of the second
    operand, not a number of digits. `quantize()` returns the same value as
    `round()` when the scale of the second operand is non-negative.

    Args:
        value: The Decimal128 value to quantize.
        exp: A Decimal128 whose scale (exponent) will be used for the result.
        rounding_mode: The rounding mode to use.
            Defaults to ROUND_HALF_EVEN (banker's rounding).

    Returns:
        A new Decimal128 with the same value as the first operand (except for
        rounding) and the same scale (exponent) as the second operand.

    Raises:
        Error: If the resulting number doesn't fit within the valid range.

    Examples:

    ```mojo
    from decimojo import Decimal128
    _ = Decimal128("1.2345").quantize(Decimal128("0.001"))  # -> Decimal128("1.234")
    _ = Decimal128("1.2345").quantize(Decimal128("0.01"))   # -> Decimal128("1.23")
    _ = Decimal128("1.2345").quantize(Decimal128("0.1"))    # -> Decimal128("1.2")
    _ = Decimal128("1.2345").quantize(Decimal128("1"))      # -> Decimal128("1")
    _ = Decimal128("1.2345").quantize(Decimal128("10"))     # -> Decimal128("1")
    # Compare with round()
    _ = Decimal128("1.2345").round(-1)                   # -> Decimal128("0")
    ```
    End of examples.
    """

    # Determine the scale of the target exponent
    var target_scale = exp.scale()
    # Determine the scale of the value
    var value_scale = value.scale()

    # If the scales are already the same, no quantization needed
    if target_scale == value_scale:
        return value

    # If the target scale is non-negative, round the value to the target scale
    elif target_scale >= 0:
        return round(value, target_scale, rounding_mode)

    # If the target scale is negative, round the value to integer
    else:
        return round(value, 0, rounding_mode)
