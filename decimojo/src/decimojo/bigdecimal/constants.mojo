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
# Implements functions for calculating common constants.
"""

import math as builtin_math

from decimojo.bigdecimal.bigdecimal import BigDecimal
from decimojo.rounding_mode import RoundingMode

alias PI_1024 = BigDecimal(
    coefficient=BigUInt(
        words=List[UInt32](
            858632789,
            572010654,
            989380952,
            92164201,
            766111959,
            130019278,
            712268066,
            577805321,
            519577818,
            537875937,
            628638823,
            687311595,
            904287554,
            35982534,
            776691473,
            814206171,
            875332083,
            387528865,
            100031378,
            311881710,
            850352619,
            82533446,
            26425223,
            553469083,
            950244594,
            160963185,
            597317328,
            780499510,
            999983729,
            72113499,
            99605187,
            297747713,
            181598136,
            608640344,
            121290219,
            420199561,
            892589235,
            507922796,
            495853710,
            534301465,
            409012249,
            787214684,
            91736371,
            427577896,
            277857713,
            452635608,
            5681271,
            694051320,
            748184676,
            767523846,
            171762931,
            27705392,
            798609437,
            371907021,
            463952247,
            860213949,
            406566430,
            336733624,
            119491298,
            279381830,
            527248912,
            673518857,
            799627495,
            480744623,
            931051185,
            819326117,
            921861173,
            595919530,
            572703657,
            116094330,
            469519415,
            665213841,
            305488204,
            600113305,
            678925903,
            917153643,
            628292540,
            815209209,
            155881748,
            870066063,
            412737245,
            72602491,
            482133936,
            104543266,
            234603486,
            456485669,
            712019091,
            867831652,
            756482337,
            334461284,
            109756659,
            819644288,
            489549303,
            596446229,
            385211055,
            841027019,
            811174502,
            594081284,
            822317253,
            446095505,
            66470938,
            865132823,
            679821480,
            253421170,
            986280348,
            62862089,
            923078164,
            209749445,
            993751058,
            841971693,
            832795028,
            384626433,
            535897932,
            31415926,
        ),
    ),
    scale=1024,
    sign=False,
)
"""Pi to 1024 digits of precision."""


# TODO: When Mojo support global variables,
# we save the value of π to a certain precision in the global scope.
# This will allow us to use it everywhere without recalculating it
# if the required precision is the same or lower.
# Everytime when user calls pi(precision),
# we check whether the precision is higher than the current precision.
# If yes, then we save it into the global scope as cached value.
fn pi(precision: Int) raises -> BigDecimal:
    """Calculates π using the fastest available algorithm."""

    if precision < 0:
        raise Error("Precision must be non-negative")

    # TODO: When global variables are supported,
    # we can check if we have a cached value for the requested precision.
    # if precision <= 1024:
    #     var result = PI_1024
    #     result.round_to_precision(
    #         precision,
    #         RoundingMode.ROUND_HALF_EVEN,
    #         remove_extra_digit_due_to_rounding=True,
    #         fill_zeros_to_precision=False,
    #     )
    #     return result^

    # Use Chudnovsky with binary splitting for maximum speed
    return pi_chudnovsky_binary_split(precision)


@fieldwise_init
struct Rational:
    """Represents a rational number p/q for exact arithmetic."""

    var p: BigInt  # numerator
    var q: BigInt  # denominator


fn pi_chudnovsky_binary_split(precision: Int) raises -> BigDecimal:
    """Calculates π using Chudnovsky algorithm with binary splitting.

    Notes:

    Use the formula:
    π = 426880 * √10005 / Σ(k=0 to ∞) [M(k) * L(k) / X(k)],
    where:
    (1) M(k) = (6k)! / ((3k)! * (k!)³)
    (2) L(k) = 545140134*k + 13591409
    (3) X(k) = (-262537412640768000)^k
    """

    var working_precision = precision + 9  # 1 words
    var iterations = (
        precision // 14
    ) + 9  # ~14.18 digits per iteration + safety margin

    var bdec_10005 = BigDecimal.from_raw_components(UInt32(10005))
    var bdec_426880 = BigDecimal.from_raw_components(UInt32(426880))

    # Binary splitting to compute the series sum as a single rational number
    var result_fraction = chudnovsky_split(0, iterations, working_precision)

    # Convert rational result to BigDecimal: q/p
    var sum_series = BigDecimal(result_fraction.q).true_divide(
        BigDecimal(result_fraction.p), working_precision
    )

    # Final formula: π = 426880 * √10005 / sum_series
    var result = bdec_426880 * bdec_10005.sqrt(working_precision) * sum_series

    result.round_to_precision(
        precision,
        RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )
    return result^


fn chudnovsky_split(a: Int, b: Int, precision: Int) raises -> Rational:
    """Conducts binary splitting for Chudnovsky series from term a to b-1."""

    var bint_1 = BigInt(1)
    var bint_13591409 = BigInt(13591409)
    var bint_545140134 = BigInt(545140134)
    var bint_262537412640768000 = BigInt(262537412640768000)

    if b - a == 1:
        # Base case: compute single term as exact rational
        if a == 0:
            # Special case for k=0: M(0)=1, L(0)=13591409, X(0)=1
            return Rational(bint_13591409, bint_1)

        # For k > 0: compute M(k), L(k), X(k)
        var m_k_rational = compute_m_k_rational(a)
        var l_k = bint_545140134 * BigInt(a) + bint_13591409

        # X(k) = (-262537412640768000)^k
        var x_k = bint_1
        for _ in range(a):
            x_k *= bint_262537412640768000

        # Apply sign: (-1)^k
        if a % 2 == 1:
            x_k = -x_k

        # Term = M(k) * L(k) / X(k) = (m_k_p * l_k) / (m_k_q * x_k)
        var term_p = m_k_rational.p * l_k
        var term_q = m_k_rational.q * x_k

        return Rational(term_p, term_q)

    # Recursive case: split range in half
    var mid = (a + b) // 2
    var left = chudnovsky_split(a, mid, precision)
    var right = chudnovsky_split(mid, b, precision)

    # Combine fractions: left.p/left.q + right.p/right.q
    var combined_p = left.p * right.q + right.p * left.q
    var combined_q = left.q * right.q

    return Rational(combined_p, combined_q)


fn compute_m_k_rational(k: Int) raises -> Rational:
    """Computes M(k) = (6k)! / ((3k)! * (k!)³) as exact rational."""

    var bint_1 = BigInt(1)

    if k == 0:
        return Rational(bint_1, bint_1)

    # Compute numerator: (6k)! / (3k)! = (3k+1) * (3k+2) * ... * (6k)
    var numerator = bint_1
    for i in range(3 * k + 1, 6 * k + 1):
        numerator *= BigInt(i)

    # Compute denominator: (k!)³
    var k_factorial = bint_1
    for i in range(1, k + 1):
        k_factorial *= BigInt(i)

    var denominator = k_factorial * k_factorial * k_factorial

    return Rational(numerator, denominator)


fn pi_machin(precision: Int) raises -> BigDecimal:
    """Fallback π calculation using Machin's formula."""

    var working_precision = precision + 9

    var bdec_1 = BigDecimal.from_raw_components(UInt32(1))
    var bdec_4 = BigDecimal.from_raw_components(UInt32(4))
    var bdec_5 = BigDecimal.from_raw_components(UInt32(5))
    var bdec_239 = BigDecimal.from_raw_components(UInt32(239))

    # Calculate 4 * arctan(1/5)
    var one_fifth = bdec_1.true_divide(bdec_5, working_precision)
    var term1 = bdec_4 * decimojo.bigdecimal.trigonometric.arctan_taylor_series(
        one_fifth, working_precision
    )

    # Calculate arctan(1/239)
    var one_239 = bdec_1.true_divide(bdec_239, working_precision)
    var term2 = decimojo.bigdecimal.trigonometric.arctan_taylor_series(
        one_239, working_precision
    )

    # π/4 = 4*arctan(1/5) - arctan(1/239)
    var pi_over_4 = term1 - term2
    var result = bdec_4 * pi_over_4

    result.round_to_precision(
        precision,
        RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )
    return result^
