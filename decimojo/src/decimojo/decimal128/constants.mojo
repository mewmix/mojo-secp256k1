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

"""Useful constants for Decimal128 type."""

from decimojo.decimal128.decimal128 import Decimal128

# ===----------------------------------------------------------------------=== #
#
# Integer and decimal constants
# The prefix "M" stands for a decimal (money) value.
# This is a convention in C.
#
# ===----------------------------------------------------------------------=== #

# Integer constants


@always_inline
fn M0() -> Decimal128:
    """Returns 0 as a Decimal128."""
    return Decimal128(0x0, 0x0, 0x0, 0x0)


@always_inline
fn M1() -> Decimal128:
    """Returns 1 as a Decimal128."""
    return Decimal128(0x1, 0x0, 0x0, 0x0)


@always_inline
fn M2() -> Decimal128:
    """Returns 2 as a Decimal128."""
    return Decimal128(0x2, 0x0, 0x0, 0x0)


@always_inline
fn M3() -> Decimal128:
    """Returns 3 as a Decimal128."""
    return Decimal128(0x3, 0x0, 0x0, 0x0)


@always_inline
fn M4() -> Decimal128:
    """Returns 4 as a Decimal128."""
    return Decimal128(0x4, 0x0, 0x0, 0x0)


@always_inline
fn M5() -> Decimal128:
    """Returns 5 as a Decimal128."""
    return Decimal128(0x5, 0x0, 0x0, 0x0)


@always_inline
fn M6() -> Decimal128:
    """Returns 6 as a Decimal128."""
    return Decimal128(0x6, 0x0, 0x0, 0x0)


@always_inline
fn M7() -> Decimal128:
    """Returns 7 as a Decimal128."""
    return Decimal128(0x7, 0x0, 0x0, 0x0)


@always_inline
fn M8() -> Decimal128:
    """Returns 8 as a Decimal128."""
    return Decimal128(0x8, 0x0, 0x0, 0x0)


@always_inline
fn M9() -> Decimal128:
    """Returns 9 as a Decimal128."""
    return Decimal128(0x9, 0x0, 0x0, 0x0)


@always_inline
fn M10() -> Decimal128:
    """Returns 10 as a Decimal128."""
    return Decimal128(0xA, 0x0, 0x0, 0x0)


# Decimal128 constants


@always_inline
fn M0D5() -> Decimal128:
    """Returns 0.5 as a Decimal128."""
    return Decimal128(5, 0, 0, 0x10000)


@always_inline
fn M0D25() -> Decimal128:
    """Returns 0.25 as a Decimal128."""
    return Decimal128(25, 0, 0, 0x20000)


# ===----------------------------------------------------------------------=== #
#
# Inverse constants
#
# ===----------------------------------------------------------------------=== #


@always_inline
fn INV2() -> Decimal128:
    """Returns 1/2 = 0.5."""
    return Decimal128(0x5, 0x0, 0x0, 0x10000)


@always_inline
fn INV10() -> Decimal128:
    """Returns 1/10 = 0.1."""
    return Decimal128(0x1, 0x0, 0x0, 0x10000)


@always_inline
fn INV0D1() -> Decimal128:
    """Returns 1/0.1 = 10."""
    return Decimal128(0xA, 0x0, 0x0, 0x0)


@always_inline
fn INV0D2() -> Decimal128:
    """Returns 1/0.2 = 5."""
    return Decimal128(0x5, 0x0, 0x0, 0x0)


@always_inline
fn INV0D3() -> Decimal128:
    """Returns 1/0.3 = 3.33333333333333333333333333333333..."""
    return Decimal128(0x35555555, 0xCF2607EE, 0x6BB4AFE4, 0x1C0000)


@always_inline
fn INV0D4() -> Decimal128:
    """Returns 1/0.4 = 2.5."""
    return Decimal128(0x19, 0x0, 0x0, 0x10000)


@always_inline
fn INV0D5() -> Decimal128:
    """Returns 1/0.5 = 2."""
    return Decimal128(0x2, 0x0, 0x0, 0x0)


@always_inline
fn INV0D6() -> Decimal128:
    """Returns 1/0.6 = 1.66666666666666666666666666666667..."""
    return Decimal128(0x1AAAAAAB, 0x679303F7, 0x35DA57F2, 0x1C0000)


@always_inline
fn INV0D7() -> Decimal128:
    """Returns 1/0.7 = 1.42857142857142857142857142857143..."""
    return Decimal128(0xCDB6DB6E, 0x3434DED3, 0x2E28DDAB, 0x1C0000)


@always_inline
fn INV0D8() -> Decimal128:
    """Returns 1/0.8 = 1.25."""
    return Decimal128(0x7D, 0x0, 0x0, 0x20000)


@always_inline
fn INV0D9() -> Decimal128:
    """Returns 1/0.9 = 1.11111111111111111111111111111111..."""
    return Decimal128(0x671C71C7, 0x450CAD4F, 0x23E6E54C, 0x1C0000)


@always_inline
fn INV1() -> Decimal128:
    """Returns 1/1 = 1."""
    return Decimal128(0x1, 0x0, 0x0, 0x0)


@always_inline
fn INV1D1() -> Decimal128:
    """Returns 1/1.1 = 0.90909090909090909090909090909091..."""
    return Decimal128(0x9A2E8BA3, 0x4FC48DCC, 0x1D5FD2E1, 0x1C0000)


@always_inline
fn INV1D2() -> Decimal128:
    """Returns 1/1.2 = 0.83333333333333333333333333333333..."""
    return Decimal128(0x8D555555, 0x33C981FB, 0x1AED2BF9, 0x1C0000)


@always_inline
fn INV1D3() -> Decimal128:
    """Returns 1/1.3 = 0.76923076923076923076923076923077..."""
    return Decimal128(0xC4EC4EC, 0x9243DA72, 0x18DAED83, 0x1C0000)


@always_inline
fn INV1D4() -> Decimal128:
    """Returns 1/1.4 = 0.71428571428571428571428571428571..."""
    return Decimal128(0xE6DB6DB7, 0x9A1A6F69, 0x17146ED5, 0x1C0000)


@always_inline
fn INV1D5() -> Decimal128:
    """Returns 1/1.5 = 0.66666666666666666666666666666667..."""
    return Decimal128(0xAAAAAAB, 0x296E0196, 0x158A8994, 0x1C0000)


@always_inline
fn INV1D6() -> Decimal128:
    """Returns 1/1.6 = 0.625."""
    return Decimal128(0x271, 0x0, 0x0, 0x30000)


@always_inline
fn INV1D7() -> Decimal128:
    """Returns 1/1.7 = 0.58823529411764705882352941176471..."""
    return Decimal128(0x45A5A5A6, 0xE8520166, 0x1301C4AF, 0x1C0000)


@always_inline
fn INV1D8() -> Decimal128:
    """Returns 1/1.8 = 0.55555555555555555555555555555556..."""
    return Decimal128(0xB38E38E4, 0x228656A7, 0x11F372A6, 0x1C0000)


@always_inline
fn INV1D9() -> Decimal128:
    """Returns 1/1.9 = 0.52631578947368421052631578947368..."""
    return Decimal128(0xAA1AF287, 0x2E2E6D0A, 0x11019509, 0x1C0000)


# ===----------------------------------------------------------------------=== #
#
# N / (N+1) constants
#
# ===----------------------------------------------------------------------=== #


@always_inline
fn N_DIVIDE_NEXT(n: Int) raises -> Decimal128:
    """
    Returns the pre-calculated value of n/(n+1) for n between 1 and 20.

    Args:
        n: An integer between 1 and 20, inclusive.

    Returns:
        A Decimal128 representing the value of n/(n+1).

    Raises:
        Error: If n is outside the range [1, 20].
    """
    if n == 1:
        # 1/2 = 0.5
        return Decimal128(0x5, 0x0, 0x0, 0x10000)
    elif n == 2:
        # 2/3 = 0.66666666666666666666666666666667...
        return Decimal128(0xAAAAAAB, 0x296E0196, 0x158A8994, 0x1C0000)
    elif n == 3:
        # 3/4 = 0.75
        return Decimal128(0x4B, 0x0, 0x0, 0x20000)
    elif n == 4:
        # 4/5 = 0.8
        return Decimal128(0x8, 0x0, 0x0, 0x10000)
    elif n == 5:
        # 5/6 = 0.83333333333333333333333333333333...
        return Decimal128(0x8D555555, 0x33C981FB, 0x1AED2BF9, 0x1C0000)
    elif n == 6:
        # 6/7 = 0.85714285714285714285714285714286...
        return Decimal128(0x7B6DB6DB, 0xEC1FB8E5, 0x1BB21E99, 0x1C0000)
    elif n == 7:
        # 7/8 = 0.875
        return Decimal128(0x36B, 0x0, 0x0, 0x30000)
    elif n == 8:
        # 8/9 = 0.88888888888888888888888888888889...
        return Decimal128(0xB8E38E39, 0x373D5772, 0x1CB8B770, 0x1C0000)
    elif n == 9:
        # 9/10 = 0.9
        return Decimal128(0x9, 0x0, 0x0, 0x10000)
    elif n == 10:
        # 10/11 = 0.90909090909090909090909090909091...
        return Decimal128(0x9A2E8BA3, 0x4FC48DCC, 0x1D5FD2E1, 0x1C0000)
    elif n == 11:
        # 11/12 = 0.91666666666666666666666666666667...
        return Decimal128(0x4EAAAAAB, 0xB8F7422E, 0x1D9E7D2B, 0x1C0000)
    elif n == 12:
        # 12/13 = 0.92307692307692307692307692307692...
        return Decimal128(0xEC4EC4F, 0xAF849FBC, 0x1DD3836A, 0x1C0000)
    elif n == 13:
        # 13/14 = 0.92857142857142857142857142857143...
        return Decimal128(0x45B6DB6E, 0x15225DA3, 0x1E00F67C, 0x1C0000)
    elif n == 14:
        # 14/15 = 0.93333333333333333333333333333333...
        return Decimal128(0x75555555, 0xD39A0238, 0x1E285A35, 0x1C0000)
    elif n == 15:
        # 15/16 = 0.9375
        return Decimal128(0x249F, 0x0, 0x0, 0x40000)
    elif n == 16:
        # 16/17 = 0.94117647058823529411764705882353...
        return Decimal128(0x3C3C3C3C, 0xD50023D, 0x1E693AB3, 0x1C0000)
    elif n == 17:
        # 17/18 = 0.94444444444444444444444444444444...
        return Decimal128(0xE471C71C, 0x3AB12CE9, 0x1E8442E7, 0x1C0000)
    elif n == 18:
        # 18/19 = 0.94736842105263157894736842105263...
        return Decimal128(0xCBCA1AF3, 0x1FED2AAC, 0x1E9C72AA, 0x1C0000)
    elif n == 19:
        # 19/20 = 0.95
        return Decimal128(0x5F, 0x0, 0x0, 0x20000)
    elif n == 20:
        # 20/21 = 0.95238095238095238095238095238095...
        return Decimal128(0x33CF3CF4, 0xCD78948D, 0x1EC5E91C, 0x1C0000)
    else:
        raise Error("N_DIVIDE_NEXT: n must be between 1 and 20, inclusive")


# ===----------------------------------------------------------------------=== #
#
# PI constants
#
# ===----------------------------------------------------------------------=== #


@always_inline
fn PI() -> Decimal128:
    """Returns the value of pi (π) as a Decimal128."""
    return Decimal128(0x41B65F29, 0xB143885, 0x6582A536, 0x1C0000)


# ===----------------------------------------------------------------------=== #
#
# EXP constants
#
# ===----------------------------------------------------------------------=== #


@always_inline
fn E() -> Decimal128:
    """
    Returns the value of Euler's number (e) as a Decimal128.

    Returns:
        A Decimal128 representation of Euler's number with maximum precision.
    """
    return Decimal128(0x857AED5A, 0xEBECDE35, 0x57D519AB, 0x1C0000)


@always_inline
fn E2() -> Decimal128:
    """Returns the value of e^2 as a Decimal128."""
    return Decimal128(0xE4DFDCAE, 0x89F7E295, 0xEEC0D6E9, 0x1C0000)


@always_inline
fn E3() -> Decimal128:
    """Returns the value of e^3 as a Decimal128."""
    return Decimal128(0x236454F7, 0x62055A80, 0x40E65DE2, 0x1B0000)


@always_inline
fn E4() -> Decimal128:
    """Returns the value of e^4 as a Decimal128."""
    return Decimal128(0x7121EFD3, 0xFB318FB5, 0xB06A87FB, 0x1B0000)


@always_inline
fn E5() -> Decimal128:
    """Returns the value of e^5 as a Decimal128."""
    return Decimal128(0xD99BD974, 0x9F4BE5C7, 0x2FF472E3, 0x1A0000)


@always_inline
fn E6() -> Decimal128:
    """Returns the value of e^6 as a Decimal128."""
    return Decimal128(0xADB57A66, 0xBD7A423F, 0x825AD8FF, 0x1A0000)


@always_inline
fn E7() -> Decimal128:
    """Returns the value of e^7 as a Decimal128."""
    return Decimal128(0x22313FCF, 0x64D5D12F, 0x236F230A, 0x190000)


@always_inline
fn E8() -> Decimal128:
    """Returns the value of e^8 as a Decimal128."""
    return Decimal128(0x1E892E63, 0xD1BF8B5C, 0x6051E812, 0x190000)


@always_inline
fn E9() -> Decimal128:
    """Returns the value of e^9 as a Decimal128."""
    return Decimal128(0x34FAB691, 0xE7CD8DEA, 0x1A2EB6C3, 0x180000)


@always_inline
fn E10() -> Decimal128:
    """Returns the value of e^10 as a Decimal128."""
    return Decimal128(0xBA7F4F65, 0x58692B62, 0x472BDD8F, 0x180000)


@always_inline
fn E11() -> Decimal128:
    """Returns the value of e^11 as a Decimal128."""
    return Decimal128(0x8C2C6D20, 0x2A86F9E7, 0xC176BAAE, 0x180000)


@always_inline
fn E12() -> Decimal128:
    """Returns the value of e^12 as a Decimal128."""
    return Decimal128(0xE924992A, 0x31CDC314, 0x3496C2C4, 0x170000)


@always_inline
fn E13() -> Decimal128:
    """Returns the value of e^13 as a Decimal128."""
    return Decimal128(0x220130DB, 0xC386029A, 0x8EF393FB, 0x170000)


@always_inline
fn E14() -> Decimal128:
    """Returns the value of e^14 as a Decimal128."""
    return Decimal128(0x3A24795C, 0xC412DF01, 0x26DBB5A0, 0x160000)


@always_inline
fn E15() -> Decimal128:
    """Returns the value of e^15 as a Decimal128."""
    return Decimal128(0x6C1248BD, 0x90456557, 0x69A0AD8C, 0x160000)


@always_inline
fn E16() -> Decimal128:
    """Returns the value of e^16 as a Decimal128."""
    return Decimal128(0xB46A97D, 0x90655BBD, 0x1CB66B18, 0x150000)


@always_inline
fn E32() -> Decimal128:
    """Returns the value of e^32 as a Decimal128."""
    return Decimal128(0x18420EB, 0xCC2501E6, 0xFF24A138, 0xF0000)


@always_inline
fn E0D5() -> Decimal128:
    """Returns the value of e^0.5 = e^(1/2) as a Decimal128."""
    return Decimal128(0x8E99DD66, 0xC210E35C, 0x3545E717, 0x1C0000)


@always_inline
fn E0D25() -> Decimal128:
    """Returns the value of e^0.25 = e^(1/4) as a Decimal128."""
    return Decimal128(0xB43646F1, 0x2654858A, 0x297D3595, 0x1C0000)


# ===----------------------------------------------------------------------=== #
#
# LN constants
#
# ===----------------------------------------------------------------------=== #

# The repr of the magic numbers can be obtained by the following code:
#
# ```mojo
# fn print_repr_words(value: String, ln_value: String) raises:
#     """
#     Prints the hex representation of a logarithm value.
#     Args:
#         value: The original value (for display purposes).
#         ln_value: The natural logarithm as a String.
#     """
#     var log_decimal = Decimal128(ln_value)
#     print("ln(" + value + "): " + log_decimal.repr_words())
# ```


# Constants for integers


@always_inline
fn LN1() -> Decimal128:
    """Returns ln(1) = 0."""
    return Decimal128(0x0, 0x0, 0x0, 0x0)


@always_inline
fn LN2() -> Decimal128:
    """Returns ln(2) = 0.69314718055994530941723212145818..."""
    return Decimal128(0xAA7A65BF, 0x81F52F01, 0x1665943F, 0x1C0000)


@always_inline
fn LN10() -> Decimal128:
    """Returns ln(10) = 2.30258509299404568401799145468436..."""
    return Decimal128(0x9FA69733, 0x1414B220, 0x4A668998, 0x1C0000)


# Constants for values less than 1
@always_inline
fn LN0D1() -> Decimal128:
    """Returns ln(0.1) = -2.30258509299404568401799145468436..."""
    return Decimal128(0x9FA69733, 0x1414B220, 0x4A668998, 0x801C0000)


@always_inline
fn LN0D2() -> Decimal128:
    """Returns ln(0.2) = -1.60943791243410037460075933322619..."""
    return Decimal128(0xF52C3174, 0x921F831E, 0x3400F558, 0x801C0000)


@always_inline
fn LN0D3() -> Decimal128:
    """Returns ln(0.3) = -1.20397280432593599262274621776184..."""
    return Decimal128(0x2B8E6822, 0x8258467, 0x26E70795, 0x801C0000)


@always_inline
fn LN0D4() -> Decimal128:
    """Returns ln(0.4) = -0.91629073187415506518352721176801..."""
    return Decimal128(0x4AB1CBB6, 0x102A541D, 0x1D9B6119, 0x801C0000)


@always_inline
fn LN0D5() -> Decimal128:
    """Returns ln(0.5) = -0.69314718055994530941723212145818..."""
    return Decimal128(0xAA7A65BF, 0x81F52F01, 0x1665943F, 0x801C0000)


@always_inline
fn LN0D6() -> Decimal128:
    """Returns ln(0.6) = -0.51082562376599068320551409630366..."""
    return Decimal128(0x81140263, 0x86305565, 0x10817355, 0x801C0000)


@always_inline
fn LN0D7() -> Decimal128:
    """Returns ln(0.7) = -0.35667494393873237891263871124118..."""
    return Decimal128(0x348BC5A8, 0x8B755D08, 0xB865892, 0x801C0000)


@always_inline
fn LN0D8() -> Decimal128:
    """Returns ln(0.8) = -0.22314355131420975576629509030983..."""
    return Decimal128(0xA03765F7, 0x8E35251B, 0x735CCD9, 0x801C0000)


@always_inline
fn LN0D9() -> Decimal128:
    """Returns ln(0.9) = -0.10536051565782630122750098083931..."""
    return Decimal128(0xB7763910, 0xFC3656AD, 0x3678591, 0x801C0000)


# Constants for values greater than 1


@always_inline
fn LN1D1() -> Decimal128:
    """Returns ln(1.1) = 0.09531017980432486004395212328077..."""
    return Decimal128(0x7212FFD1, 0x7D9A10, 0x3146328, 0x1C0000)


@always_inline
fn LN1D2() -> Decimal128:
    """Returns ln(1.2) = 0.18232155679395462621171802515451..."""
    return Decimal128(0x2966635C, 0xFBC4D99C, 0x5E420E9, 0x1C0000)


@always_inline
fn LN1D3() -> Decimal128:
    """Returns ln(1.3) = 0.26236426446749105203549598688095..."""
    return Decimal128(0xE0BE71FD, 0xC254E078, 0x87A39F0, 0x1C0000)


@always_inline
fn LN1D4() -> Decimal128:
    """Returns ln(1.4) = 0.33647223662121293050459341021699..."""
    return Decimal128(0x75EEA016, 0xF67FD1F9, 0xADF3BAC, 0x1C0000)


@always_inline
fn LN1D5() -> Decimal128:
    """Returns ln(1.5) = 0.40546510810816438197801311546435..."""
    return Decimal128(0xC99DC953, 0x89F9FEB7, 0xD19EDC3, 0x1C0000)


@always_inline
fn LN1D6() -> Decimal128:
    """Returns ln(1.6) = 0.47000362924573555365093703114834..."""
    return Decimal128(0xA42FFC8, 0xF3C009E6, 0xF2FC765, 0x1C0000)


@always_inline
fn LN1D7() -> Decimal128:
    """Returns ln(1.7) = 0.53062825106217039623154316318876..."""
    return Decimal128(0x64BB9ED0, 0x4AB9978F, 0x11254107, 0x1C0000)


@always_inline
fn LN1D8() -> Decimal128:
    """Returns ln(1.8) = 0.58778666490211900818973114061886..."""
    return Decimal128(0xF3042CAE, 0x85BED853, 0x12FE0EAD, 0x1C0000)


@always_inline
fn LN1D9() -> Decimal128:
    """Returns ln(1.9) = 0.64185388617239477599103597720349..."""
    return Decimal128(0x12F992DC, 0xE7374425, 0x14BD4A78, 0x1C0000)
