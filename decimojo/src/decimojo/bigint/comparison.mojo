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
Implements functions for comparison operations on BigInt objects.
"""

from decimojo.bigint.bigint import BigInt
from decimojo.biguint.biguint import BigUInt


fn compare_magnitudes(x1: BigInt, x2: BigInt) -> Int8:
    """Compares the magnitudes of two numbers and returns the result.

    Args:
        x1: First number.
        x2: Second number.

    Returns:
        Terinary value indicating the comparison result:
        (1)  1 if |x1| > |x2|.
        (2)  0 if |x1| = |x2|.
        (3) -1 if |x1| < |x2|.
    """
    return x1.magnitude.compare(x2.magnitude)


fn compare(x1: BigInt, x2: BigInt) -> Int8:
    """Compares two BigInt objects and returns the result.

    Args:
        x1: First number.
        x2: Second number.

    Returns:
        Terinary value indicating the comparison result:
        (1)  1 if x1 > x2.
        (2)  0 if x1 = x2.
        (3) -1 if x1 < x2.
    """
    if x1.is_zero() and x2.is_zero():
        return 0

    # Different signs: negative < positive
    if x1.sign != x2.sign:
        return -1 if x1.sign else 1

    # Same signs: compare magnitudes
    var magnitude_comparison = compare_magnitudes(x1, x2)

    # If both negative, reverse the comparison result
    return magnitude_comparison if not x1.sign else -magnitude_comparison


fn greater(x1: BigInt, x2: BigInt) -> Bool:
    """Checks if the first number is greater than the second.

    Args:
        x1: First signed integer.
        x2: Second signed integer.

    Returns:
        True if x1 > x2, False otherwise.
    """
    return compare(x1, x2) > 0


fn greater_equal(x1: BigInt, x2: BigInt) -> Bool:
    """Checks if the first number is greater than or equal to the second.

    Args:
        x1: First signed integer.
        x2: Second signed integer.

    Returns:
        True if x1 >= x2, False otherwise.
    """
    return compare(x1, x2) >= 0


fn less(x1: BigInt, x2: BigInt) -> Bool:
    """Checks if the first number is less than the second.

    Args:
        x1: First signed integer.
        x2: Second signed integer.

    Returns:
        True if x1 < x2, False otherwise.
    """
    return compare(x1, x2) < 0


fn less_equal(x1: BigInt, x2: BigInt) -> Bool:
    """Checks if the first number is less than or equal to the second.

    Args:
        x1: First signed integer.
        x2: Second signed integer.

    Returns:
        True if x1 <= x2, False otherwise.
    """
    return compare(x1, x2) <= 0


fn equal(x1: BigInt, x2: BigInt) -> Bool:
    """Checks if two numbers are equal.

    Args:
        x1: First signed integer.
        x2: Second signed integer.

    Returns:
        True if x1 == x2, False otherwise.
    """
    return compare(x1, x2) == 0


fn not_equal(x1: BigInt, x2: BigInt) -> Bool:
    """Checks if two numbers are not equal.

    Args:
        x1: First signed integer.
        x2: Second signed integer.

    Returns:
        True if x1 != x2, False otherwise.
    """
    return compare(x1, x2) != 0
