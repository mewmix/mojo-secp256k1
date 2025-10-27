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

"""Implements basic object methods for the BigUInt type.

This module contains the basic object methods for the BigUInt type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.
"""

from memory import UnsafePointer, memcpy, memcmp

import decimojo.biguint.arithmetics
import decimojo.biguint.comparison
from decimojo.errors import (
    DeciMojoError,
    ConversionError,
    ValueError,
    IndexError,
    OverflowError,
)
import decimojo.str

# Type aliases
alias BUInt = BigUInt
alias BigUInt10 = BigUInt


struct BigUInt(
    Absable,
    Copyable,
    ImplicitlyCopyable,
    IntableRaising,
    Movable,
    Stringable,
    Writable,
):
    """Represents a base-10 arbitrary-precision unsigned integer.

    Notes:

    Internal Representation:

    Use base-10^9 (base-billion) representation for the unsigned integer.
    BigUInt uses a dynamic structure in memory, which contains:
    An pointer to an array of UInt32 words for the coefficient on the heap,
    which can be of arbitrary length stored in little-endian order.
    Each UInt32 word represents digits ranging from 0 to 10^9 - 1.

    The value of the BigUInt is calculated as follows:

    x = x[0] * 10^0 + x[1] * 10^9 + x[2] * 10^18 + ... x[n] * 10^(9n)

    You can think of the BigUInt as a list base-billion digits, where each
    digit is ranging from 0 to 999_999_999. Depending on the context, the
    following terms are used interchangeably:
    (1) words,
    (2) limbs,
    (3) base-billion digits.
    """

    var words: List[UInt32]
    """A list of UInt32 words representing the coefficient."""

    fn __copyinit__(out self, other: Self):
        self.words = other.words.copy()

    fn __moveinit__(out self, deinit other: Self):
        self.words = other.words^

    # ===------------------------------------------------------------------=== #
    # Constants
    # ===------------------------------------------------------------------=== #

    # TODO: Make these constants global, e.g., decimojo.BASE
    alias BASE = 1_000_000_000
    """The base used for the BigUInt representation."""
    alias BASE_MAX = 999_999_999
    """The maximum value of a single word in the BigUInt representation."""
    alias BASE_HALF = 500_000_000
    """Half of the base used for the BigUInt representation."""
    alias VECTOR_WIDTH = 4
    """The width of the SIMD vector used for arithmetic operations (128-bit)."""

    alias ZERO = Self.zero()
    alias ONE = Self.one()
    alias MAX_UINT64 = Self(709551615, 446744073, 18)
    alias MAX_UINT128 = Self(768211455, 374607431, 938463463, 282366920, 340)

    @always_inline
    @staticmethod
    fn zero() -> Self:
        """Returns a BigUInt with value 0."""
        return Self()

    @always_inline
    @staticmethod
    fn one() -> Self:
        """Returns a BigUInt with value 1."""
        return Self(words=List[UInt32](UInt32(1)))

    @staticmethod
    @always_inline
    fn power_of_10(exponent: Int) raises -> Self:
        """Calculates 10^exponent efficiently."""
        return decimojo.biguint.arithmetics.power_of_10(exponent)

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    #
    # __init__(out self)
    # __init__(out self, var words: List[UInt32])
    # __init__(out self, var *words: UInt32)
    # __init__(out self, value: Int) raises
    # __init__(out self, value: Scalar) raises
    # __init__(out self, value: String, ignore_sign: Bool = False) raises
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes a BigUInt with value 0."""
        self.words = List[UInt32](UInt32(0))

    fn __init__(out self, *, uninitialized_capacity: Int):
        """Creates an uninitialized BigUInt with a given capacity.

        Args:
            uninitialized_capacity: The capacity of the BigUInt.
                This is the number of UInt32 words that can be stored in the
                BigUInt without reallocating memory.

        Notes:

        The length of the BigUInt is zero.
        """
        self.words = List[UInt32](capacity=uninitialized_capacity)

    fn __init__(out self, *, unsafe_uninit_length: Int):
        """Creates an uninitialized BigUInt with a given length.

        Args:
            unsafe_uninit_length: The length of the BigUInt.

        Notes:

        The length of the BigUInt is `unsafe_uninit_length`.
        """
        self.words = List[UInt32](unsafe_uninit_length=unsafe_uninit_length)

    fn __init__(out self, var words: List[UInt32]):
        """Initializes a BigUInt from a list of UInt32 words.
        If the list is empty, the BigUInt is initialized with value 0.
        If there are trailing empty words, they are NOT removed.
        This method does NOT check whether the words are smaller than
        `999_999_999`.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Notes:

        If you want to remove trailing empty words and validate the words,
        use `BigUInt.from_list_unsafe()`.
        If you also want to validate the words and remove trailing empty words,
        use `BigUInt.from_list()`.
        """
        if len(words) == 0:
            self.words = List[UInt32](UInt32(0))
        else:
            self.words = words^

    fn __init__(out self, var *words: UInt32):
        """Initializes a BigUInt from raw words without validating the words.
        See `from_words()` for safer initialization.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Notes:

        This method does not check whether the words are smaller than
        `999_999_999`.

        Example:

        ```console
        BigUInt(123456789, 987654321) # 987654321_123456789
        ```
        End of examples.
        """
        self.words = List[UInt32](elements=words^)

    fn __init__(out self, value: Int) raises:
        """Initializes a BigUInt from an Int.
        See `from_int()` for more information.

        Raises:
            Error: Calling `BigUInt.from_int()`.
        """
        try:
            self = Self.from_int(value)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__init__(value: Int)",
                    message=None,
                    previous_error=e,
                )
            )

    @implicit
    fn __init__(out self, value: UInt):
        """Initializes a BigUInt from an UInt.
        See `from_uint()` for more information.
        """
        self = Self.from_uint(value)

    @implicit
    fn __init__(out self, value: UInt32):
        """Initializes a BigUInt from an UInt32.
        See `from_uint32()` for more information.
        """
        self = Self.from_uint32(value)

    @implicit
    fn __init__(out self, value: Scalar):
        """Initializes a BigUInt from an unsigned integral scalar.
        See `from_unsigned_integral_scalar()` for more information.
        """
        self = Self.from_unsigned_integral_scalar(value)

    fn __init__(out self, value: String, ignore_sign: Bool = False) raises:
        """Initializes a BigUInt from a string representation.

        Args:
            value: The string representation of the BigUInt.
            ignore_sign: A Bool value indicating whether to ignore the sign.
                If True, the sign is ignored.
                If False, the sign is considered.

        Raises:
            Error: If an error occurs in `from_string()`.
        """
        try:
            self = Self.from_string(value, ignore_sign=ignore_sign)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__init__(value: String)",
                    message=None,
                    previous_error=e,
                )
            )

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    #
    # from_list(var words: List[UInt32]) -> Self
    # from_words(*words: UInt32) -> Self
    # from_int(value: Int) -> Self
    # from_unsigned_integral_scalar[dtype: DType](value: Scalar[dtype]) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_list(var words: List[UInt32]) raises -> Self:
        """Initializes a BigUInt from a list of UInt32 words safely.
        If the list is empty, the BigUInt is initialized with value 0.
        If there are trailing empty words, they are removed.
        The words are validated to ensure they are smaller than `999_999_999`.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Raises:
            Error: If any word is larger than `999_999_999`.

        Returns:
            The BigUInt representation of the list of UInt32 words.
        """
        # Return 0 if the list is empty
        if len(words) == 0:
            return Self()

        # Check if the words are valid
        for word in words:
            if word > UInt32(999_999_999):
                raise Error(
                    OverflowError(
                        message=(
                            "Word value "
                            + String(word)
                            + " exceeds maximum value of 999_999_999"
                        ),
                        function="BigUInt.from_list()",
                        file="src/decimojo/biguint/biguint.mojo",
                        previous_error=None,
                    )
                )

        var res = Self(words^)
        res.remove_leading_empty_words()
        return res^

    @staticmethod
    fn from_list_unsafe(var words: List[UInt32]) -> Self:
        """Initializes a BigUInt from a list of UInt32 words without checks.
        If the list is empty, the BigUInt is initialized with value 0.
        If there are trailing empty words, they are removed.
        The words are not validated to ensure they are smaller than a billion.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Returns:
            The BigUInt representation of the list of UInt32 words.
        """
        var result = Self(words=words^)
        result.remove_leading_empty_words()
        return result^

    @staticmethod
    fn from_words(*words: UInt32) raises -> Self:
        """Initializes a BigUInt from raw words safely.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Raises:
            Error: If any word is larger than `999_999_999`.

        Notes:

        This method validates whether the words are smaller than `999_999_999`.

        Example:

        ```console
        BigUInt.from_words(123456789, 987654321) # 987654321_123456789
        ```
        End of examples.
        """

        var list_of_words = List[UInt32](capacity=len(words))

        # Check if the words are valid
        for word in words:
            if word > UInt32(999_999_999):
                raise Error(
                    OverflowError(
                        message=(
                            "Word value "
                            + String(word)
                            + " exceeds maximum value of 999_999_999"
                        ),
                        function="BigUInt.from_words()",
                        file="src/decimojo/biguint/biguint.mojo",
                        previous_error=None,
                    )
                )
            else:
                list_of_words.append(word)

        return Self(list_of_words^)

    @staticmethod
    fn from_slice(value: Self, bounds: Tuple[Int, Int]) -> Self:
        """Initializes a BigUInt from a BigUInt slice.

        Args:
            value: The BigUInt to copy from.
            bounds: A tuple of two integers representing the bounds
                for the words to copy.
                The first integer is the start index (inclusive),
                and the second integer is the end index (exclusive).
        """
        # Safty checks on bounds
        var start_index: Int
        var end_index: Int

        if bounds[0] < 0:
            start_index = 0
        else:
            start_index = bounds[0]

        if bounds[1] > len(value.words):
            end_index = len(value.words)
        else:
            end_index = bounds[1]

        var n_words = end_index - start_index
        if n_words <= 0:
            return Self()

        # Now we can safely copy the words
        result = BigUInt(unsafe_uninit_length=n_words)
        memcpy(
            dest=result.words._data,
            src=value.words._data + start_index,
            count=n_words,
        )
        result.remove_leading_empty_words()
        return result^

    @staticmethod
    fn from_int(value: Int) raises -> Self:
        """Creates a BigUInt from an integer.

        Args:
            value: The integer value to be converted to BigUInt.

        Returns:
            The BigUInt representation of the integer value.

        Raises:
            Error: If the input value is negative.
        """
        if value == 0:
            return Self()

        if value < 0:
            raise Error(
                OverflowError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.from_int(value: Int)",
                    message=(
                        "The input value "
                        + String(value)
                        + " is negative and is not compatible with BigUInt."
                    ),
                    previous_error=None,
                )
            )

        var list_of_words = List[UInt32]()
        var remainder: Int = value
        var quotient: Int

        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            list_of_words.append(UInt32(remainder))
            remainder = quotient

        return Self(list_of_words^)

    @staticmethod
    fn from_uint(value: UInt) -> Self:
        """Creates a BigUInt from an `UInt` object."""
        if value == 0:
            return Self()

        var list_of_words = List[UInt32]()
        var remainder: Int = value
        var quotient: Int

        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            list_of_words.append(UInt32(remainder))
            remainder = quotient

        return Self(list_of_words^)

    @staticmethod
    fn from_uint32(value: UInt32) -> Self:
        """Creates a BigUInt from an `UInt32` object.

        Notes:

        UInt32 is special, so we have a separate method for it.
        """
        # One word is enough
        if value <= 999_999_999:
            return Self(words=List[UInt32](value))

        # Two words are needed
        else:
            return Self(
                words=List[UInt32](
                    value % UInt32(1_000_000_000),
                    value // UInt32(1_000_000_000),
                )
            )

    @staticmethod
    fn from_uint32_unsafe(unsafe_value: UInt32) -> Self:
        """Creates a BigUInt from an `UInt32` object without checking the value.
        """
        return Self(words=List[UInt32](unsafe_value))

    @staticmethod
    fn from_unsigned_integral_scalar[
        dtype: DType, //
    ](value: SIMD[dtype, 1]) -> Self:
        """Initializes a BigUInt from an unsigned integral scalar.
        This includes all SIMD unsigned integral types, such as UInt8, UInt16,
        UInt32, UInt64, etc.

        Constraints:
            The dtype must be integral and unsigned.

        Args:
            value: The Scalar value to be converted to BigUInt.

        Returns:
            The BigUInt representation of the Scalar value.
        """

        constrained[
            dtype.is_integral() and dtype.is_unsigned(),
            "dtype must be unsigned integral.",
        ]()

        @parameter
        if (dtype == DType.uint8) or (dtype == DType.uint16):
            return Self(words=List[UInt32](UInt32(value)))

        if value == 0:
            return Self()

        var list_of_words = List[UInt32]()
        var remainder: Scalar[dtype] = value
        var quotient: Scalar[dtype]

        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            list_of_words.append(UInt32(remainder))
            remainder = quotient

        return Self(words=list_of_words^)

    @staticmethod
    fn from_absolute_integral_scalar[
        dtype: DType, //
    ](value: SIMD[dtype, 1]) -> Self:
        """Initializes a BigUInt from an integral scalar and ignores the sign.
        This includes all SIMD integral types, such as UInt8, UInt16, Int32,
        Int64, Int128, etc.

        Constraints:
            The dtype must be integral and unsigned.

        Args:
            value: The Scalar value to be converted to BigUInt.

        Returns:
            The BigUInt representation of the Scalar value.
        """

        constrained[dtype.is_integral(), "dtype must be integral."]()

        @parameter
        if (
            (dtype == DType.uint8)
            or (dtype == DType.uint16)
            or (dtype == DType.uint32)
        ):
            # For types that are smaller than word size
            # We can directly convert them to UInt32
            return Self(words=List[UInt32](UInt32(value)))

        elif (dtype == DType.int8) or (dtype == DType.int16):
            # For signed types that are smaller than 1_000_000_000,
            # we need to handle it differently
            if value < 0:
                # Because -Int16.MIN == Int16.MAX + 1,
                # we need to handle the case by converting it to Int32
                # before taking the absolute value.
                return Self(List[UInt32](UInt32(-Int32(value))))
            else:
                return Self(List[UInt32](UInt32(value)))

        else:
            if value == 0:
                return BigUInt.ZERO

            var sign = True if value < 0 else False

            var list_of_words = List[UInt32]()
            var remainder: Scalar[dtype] = value
            var quotient: Scalar[dtype]

            if sign:
                while remainder != 0:
                    quotient = remainder // (-1_000_000_000)
                    remainder = remainder % (-1_000_000_000)
                    list_of_words.append(UInt32(-remainder))
                    remainder = -quotient
            else:
                while remainder != 0:
                    quotient = remainder // 1_000_000_000
                    remainder = remainder % 1_000_000_000
                    list_of_words.append(UInt32(remainder))
                    remainder = quotient

            return Self(list_of_words^)

    @staticmethod
    fn from_string(value: String, ignore_sign: Bool = False) raises -> BigUInt:
        """Initializes a BigUInt from a string representation.
        The string is normalized with `deciomojo.str.parse_numeric_string()`.

        Args:
            value: The string representation of the BigUInt.
            ignore_sign: A Bool value indicating whether to ignore the sign.
                If True, the sign is ignored.
                If False, the sign is considered.

        Raises:
            OverflowError: If the input value is negative and `ignore_sign` is
                False.
            ConversionError: If the input value is not a valid integer string.
                The scale is larger than the number of digits.
            ConversionError: If the input value is not an integer string.
                The fractional part is not zero.

        Returns:
            The BigUInt representation of the string.
        """
        var parsed = decimojo.str.parse_numeric_string(value)
        var coef = parsed[0].copy()
        var scale = parsed[1]
        var sign = parsed[2]

        if (not ignore_sign) and sign:
            raise Error(
                OverflowError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.from_string(value: String)",
                    message=(
                        'The input value "'
                        + value
                        + '" is negative but `ignore_sign` is False.\n'
                        + "Consider using `ignore_sign=True` to ignore the"
                        " sign."
                    ),
                    previous_error=None,
                )
            )

        # Check if the number is zero
        if len(coef) == 1 and coef[0] == UInt8(0):
            return Self()

        # Check whether the number is an integer
        # If the fractional part is not zero, raise an error
        # If the fractional part is zero, remove the fractional part
        if scale > 0:
            if scale >= len(coef):
                raise Error(
                    ConversionError(
                        file="src/decimojo/biguint/biguint.mojo",
                        function="BigUInt.from_string(value: String)",
                        message=(
                            'The input value "'
                            + value
                            + '" is not an integer.\n'
                            + "The scale is larger than the number of digits."
                        ),
                        previous_error=None,
                    )
                )
            for i in range(1, scale + 1):
                if coef[-i] != 0:
                    raise Error(
                        ConversionError(
                            file="src/decimojo/biguint/biguint.mojo",
                            function="BigUInt.from_string(value: String)",
                            message=(
                                'The input value "'
                                + value
                                + '" is not an integer.\n'
                                + "The fractional part is not zero."
                            ),
                            previous_error=None,
                        )
                    )
            coef.resize(len(coef) - scale, UInt8(0))
            scale = 0

        var number_of_digits = len(coef) - scale
        var number_of_words = number_of_digits // 9
        if number_of_digits % 9 != 0:
            number_of_words += 1

        var result_words = List[UInt32](capacity=number_of_words)

        if scale == 0:
            # This is a true integer
            var end: Int = number_of_digits
            var start: Int
            while end >= 9:
                start = end - 9
                var word: UInt32 = 0
                for digit in coef[start:end]:
                    word = word * 10 + UInt32(digit)
                result_words.append(word)
                end = start
            if end > 0:
                var word: UInt32 = 0
                for digit in coef[0:end]:
                    word = word * 10 + UInt32(digit)
                result_words.append(word)

            return Self(result_words^)

        else:  # scale < 0
            # This is a true integer with postive exponent
            var number_of_trailing_zero_words = -scale // 9
            var remaining_trailing_zero_digits = -scale % 9

            for _ in range(number_of_trailing_zero_words):
                result_words.append(UInt32(0))

            for _ in range(remaining_trailing_zero_digits):
                coef.append(UInt8(0))

            var end: Int = (
                number_of_digits + scale + remaining_trailing_zero_digits
            )
            var start: Int
            while end >= 9:
                start = end - 9
                var word: UInt32 = 0
                for digit in coef[start:end]:
                    word = word * 10 + UInt32(digit)
                result_words.append(word)
                end = start
            if end > 0:
                var word: UInt32 = 0
                for digit in coef[0:end]:
                    word = word * 10 + UInt32(digit)
                result_words.append(word)

            return Self(result_words^)

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # ===------------------------------------------------------------------=== #

    fn __int__(self) raises -> Int:
        """Returns the number as Int.

        Returns:
            The number as Int.

        Raises:
            Error: If to_int() raises an error.
        """
        try:
            return self.to_int()
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__int__()",
                    message=None,
                    previous_error=e,
                )
            )

    fn __str__(self) -> String:
        """Returns string representation of the BigUInt.
        See `to_string()` for more information.
        """
        return self.to_string()

    fn __repr__(self) -> String:
        """Returns a string representation of the BigUInt."""
        return 'BigUInt("' + self.__str__() + '")'

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn write_to[W: Writer](self, mut writer: W):
        """Writes the BigUInt to a writer.
        This implement the `write` method of the `Writer` trait.
        """
        writer.write(String(self))

    fn to_int(self) raises -> Int:
        """Returns the number as Int.

        Returns:
            The number as Int.

        Raises:
            OverflowError: If the number exceeds the size of Int (2^63-1).
        """

        # 2^63-1 = 9_223_372_036_854_775_807
        # is larger than 10^18 -1 but smaller than 10^27 - 1

        var overflow_error: Error = Error(
            OverflowError(
                file="src/decimojo/biguint/biguint.mojo",
                function="BigUInt.to_int()",
                message="The number exceeds the size of Int ("
                + String(Int.MAX)
                + ")",
                previous_error=None,
            )
        )
        if len(self.words) > 3:
            raise overflow_error

        var value: Int128 = 0
        for i in range(len(self.words)):
            value += Int128(self.words[i]) * Int128(1_000_000_000) ** i

        if value > Int128(Int.MAX):
            raise overflow_error

        return Int(value)

    fn to_uint64(self) raises -> UInt64:
        """Returns the number as UInt64.

        Returns:
            The number as UInt64.

        Raises:
            Error: If the number exceeds the size of UInt64.
        """
        if self.is_uint64_overflow():
            raise Error(
                OverflowError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.to_uint64()",
                    message=(
                        "The number exceeds the size of UInt64 ("
                        + String(UInt64.MAX)
                        + ")"
                    ),
                    previous_error=None,
                )
            )

        if len(self.words) == 1:
            return self.words._data.load[width=1]().cast[DType.uint64]()
        elif len(self.words) == 2:
            return (
                self.words._data.load[width=2]().cast[DType.uint64]()
                * SIMD[DType.uint64, 2](1, 1_000_000_000)
            ).reduce_add()
        else:
            return (
                self.words._data.load[width=4]().cast[DType.uint64]()
                * SIMD[DType.uint64, 4](
                    1,
                    1_000_000_000,
                    1_000_000_000_000_000_000,
                    0,
                )
            ).reduce_add()

    fn to_uint64_with_first_2_words(self) -> UInt64:
        """Convert the first two words of the BigUInt to UInt64.

        Notes:
            This method quickly convert BigUInt with 2 words into UInt64.
        """
        if len(self.words) == 1:
            return self.words._data.load[width=1]().cast[DType.uint64]()
        else:  # len(self.words) == 2
            return (
                self.words._data.load[width=2]().cast[DType.uint64]()
                * SIMD[DType.uint64, 2](1, 1_000_000_000)
            ).reduce_add()

    fn to_uint128(self) -> UInt128:
        """Returns the number as UInt128.
        **UNSAFE** You need to ensure that the number of words is less than 5.

        Returns:
            The number as UInt128.
        """

        # FIXME: Due to an unknown bug in Mojo,
        # The returned value changed in the caller when we use raises
        # So I have to comment out the raises part
        # In the future, we need to fix this bug and add raises back
        #
        # if self.is_uint128_overflow():
        #     raise Error(
        #         "`BigUInt.to_int()`: The number exceeds the size"
        #         " of UInt128 (340282366920938463463374607431768211455)"
        #     )

        var result: UInt128 = 0

        if len(self.words) == 1:
            result = self.words._data.load[width=1]().cast[DType.uint128]()
        elif len(self.words) == 2:
            result = (
                self.words._data.load[width=2]().cast[DType.uint128]()
                * SIMD[DType.uint128, 2](1, 1_000_000_000)
            ).reduce_add()
        elif len(self.words) == 3:
            result = (
                self.words._data.load[width=4]().cast[DType.uint128]()
                * SIMD[DType.uint128, 4](
                    1, 1_000_000_000, 1_000_000_000_000_000_000, 0
                )
            ).reduce_add()
        elif len(self.words) == 4:
            result = (
                self.words._data.load[width=4]().cast[DType.uint128]()
                * SIMD[DType.uint128, 4](
                    1,
                    1_000_000_000,
                    1_000_000_000_000_000_000,
                    1_000_000_000_000_000_000_000_000_000,
                )
            ).reduce_add()
        else:
            result = (
                self.words._data.load[width=8]().cast[DType.uint128]()
                * SIMD[DType.uint128, 8](
                    1,
                    1_000_000_000,
                    1_000_000_000_000_000_000,
                    1_000_000_000_000_000_000_000_000_000,
                    1_000_000_000_000_000_000_000_000_000_000_000_000,
                    0,
                    0,
                    0,
                )
            ).reduce_add()

        return result

    fn to_uint128_with_first_4_words(self) -> UInt128:
        """Convert the first four words of the BigUInt to UInt128.

        Notes:
            This method quickly convert BigUInt with 4 words into UInt128.
        """

        if len(self.words) == 1:
            return self.words._data.load[width=1]().cast[DType.uint128]()
        elif len(self.words) == 2:
            return (
                self.words._data.load[width=2]().cast[DType.uint128]()
                * SIMD[DType.uint128, 2](1, 1_000_000_000)
            ).reduce_add()
        elif len(self.words) == 3:
            return (
                self.words._data.load[width=4]().cast[DType.uint128]()
                * SIMD[DType.uint128, 4](
                    1, 1_000_000_000, 1_000_000_000_000_000_000, 0
                )
            ).reduce_add()
        else:  # len(self.words) == 4
            return (
                self.words._data.load[width=4]().cast[DType.uint128]()
                * SIMD[DType.uint128, 4](
                    1,
                    1_000_000_000,
                    1_000_000_000_000_000_000,
                    1_000_000_000_000_000_000_000_000_000,
                )
            ).reduce_add()

    fn to_string(self, line_width: Int = 0) -> String:
        """Returns string representation of the BigUInt.

        Args:
            line_width: The width of each line. Default is 0, which means no
                line width.

        Returns:
            The string representation of the BigUInt.
        """

        if len(self.words) == 0:
            return String("Unitilialized BigUInt")

        if self.is_zero():
            debug_assert(
                len(self.words) == 1, "There are trailing empty words."
            )
            return String("0")

        var result = String("")

        for i in range(len(self.words) - 1, -1, -1):
            if i == len(self.words) - 1:
                result += String(self.words[i])
            else:
                result += String(self.words[i]).rjust(width=9, fillchar="0")

        if line_width > 0:
            var start = 0
            var end = line_width
            var lines = List[String](capacity=len(result) // line_width + 1)
            while end < len(result):
                lines.append(result[start:end])
                start = end
                end += line_width
            lines.append(result[start:])
            result = String("\n").join(lines^)

        return result^

    fn to_string_with_separators(self, separator: String = "_") -> String:
        """Returns string representation of the BigUInt with separators.

        Args:
            separator: The separator string. Default is "_".

        Returns:
            The string representation of the BigUInt with separators.
        """

        var result = self.to_string()
        var end = len(result)
        var start = end - 3
        var blocks = List[String](capacity=len(result) // 3 + 1)
        while start > 0:
            blocks.append(result[start:end])
            end = start
            start = end - 3
        blocks.append(result[0:end])
        blocks.reverse()
        result = separator.join(blocks)

        return result^

    # ===------------------------------------------------------------------=== #
    # Type-conversion methods that are unsafe
    # ===------------------------------------------------------------------=== #

    # ===------------------------------------------------------------------=== #
    # Basic unary operation dunders
    # neg
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __abs__(self) -> Self:
        """Returns the absolute value of this number.
        See `absolute()` for more information.
        """
        return decimojo.biguint.arithmetics.absolute(self)

    @always_inline
    fn __neg__(self) raises -> Self:
        """Returns the negation of this number.
        See `negative()` for more information.
        """
        return decimojo.biguint.arithmetics.negative(self)

    @always_inline
    fn __rshift__(self, shift_amount: Int) -> Self:
        """Returns the result of floored divison by 2 to the power of `shift_amount`.
        """
        var result = self
        for _ in range(shift_amount):
            decimojo.biguint.arithmetics.floor_divide_inplace_by_2(result)
        return result^

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __add__(self, other: Self) -> Self:
        return decimojo.biguint.arithmetics.add(self, other)

    @always_inline
    fn __sub__(self, other: Self) raises -> Self:
        try:
            return decimojo.biguint.arithmetics.subtract(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__sub__(other: Self)",
                    message=None,
                    previous_error=e,
                )
            )

    @always_inline
    fn __mul__(self, other: Self) -> Self:
        return decimojo.biguint.arithmetics.multiply(self, other)

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        try:
            return decimojo.biguint.arithmetics.floor_divide(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__floordiv__(other: Self)",
                    message=None,
                    previous_error=e,
                )
            )

    @always_inline
    fn __ceildiv__(self, other: Self) raises -> Self:
        """Returns the result of ceiling division."""
        try:
            return decimojo.biguint.arithmetics.ceil_divide(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__ceildiv__(other: Self)",
                    message=None,
                    previous_error=e,
                )
            )

    @always_inline
    fn __mod__(self, other: Self) raises -> Self:
        try:
            return decimojo.biguint.arithmetics.floor_modulo(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__mod__(other: Self)",
                    message=None,
                    previous_error=e,
                )
            )

    @always_inline
    fn __divmod__(self, other: Self) raises -> Tuple[Self, Self]:
        try:
            return decimojo.biguint.arithmetics.floor_divide_modulo(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__divmod__(other: Self)",
                    message=None,
                    previous_error=e,
                )
            )

    @always_inline
    fn __pow__(self, exponent: Self) raises -> Self:
        try:
            return self.power(exponent)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__pow__(exponent: Self)",
                    message=None,
                    previous_error=e,
                )
            )

    @always_inline
    fn __pow__(self, exponent: Int) raises -> Self:
        try:
            return self.power(exponent)
        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.__pow__(exponent: Int)",
                    message=None,
                    previous_error=e,
                )
            )

    # ===------------------------------------------------------------------=== #
    # Basic binary right-side arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __radd__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.add(self, other)

    @always_inline
    fn __rsub__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.subtract(other, self)

    @always_inline
    fn __rmul__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.multiply(self, other)

    @always_inline
    fn __rfloordiv__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.floor_divide(other, self)

    @always_inline
    fn __rmod__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.floor_modulo(other, self)

    @always_inline
    fn __rdivmod__(self, other: Self) raises -> Tuple[Self, Self]:
        return decimojo.biguint.arithmetics.floor_divide_modulo(other, self)

    @always_inline
    fn __rpow__(self, base: Self) raises -> Self:
        return base.power(self)

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # These methods are called to implement the binary augmented arithmetic
    # assignments
    # (+=, -=, *=, @=, /=, //=, %=, **=, <<=, >>=, &=, ^=, |=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self):
        """Adds `other` to `self` in place.
        See `biguint.arithmetics.add_inplace()` for more information.
        """
        decimojo.biguint.arithmetics.add_inplace(self, other)

    @always_inline
    fn __isub__(mut self, other: Self) raises:
        """Subtracts `other` from `self` in place.
        See `biguint.arithmetics.subtract_inplace()` for more information.
        """
        decimojo.biguint.arithmetics.subtract_inplace(self, other)

    @always_inline
    fn __imul__(mut self, other: Self) raises:
        self = decimojo.biguint.arithmetics.multiply(self, other)

    @always_inline
    fn __ifloordiv__(mut self, other: Self) raises:
        self = decimojo.biguint.arithmetics.floor_divide(self, other)

    @always_inline
    fn __imod__(mut self, other: Self) raises:
        self = decimojo.biguint.arithmetics.floor_modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Basic binary comparison operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __gt__(self, other: Self) -> Bool:
        """Returns True if self > other."""
        return decimojo.biguint.comparison.greater(self, other)

    @always_inline
    fn __ge__(self, other: Self) -> Bool:
        """Returns True if self >= other."""
        return decimojo.biguint.comparison.greater_equal(self, other)

    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        """Returns True if self < other."""
        return decimojo.biguint.comparison.less(self, other)

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        """Returns True if self <= other."""
        return decimojo.biguint.comparison.less_equal(self, other)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self == other."""
        return decimojo.biguint.comparison.equal(self, other)

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Returns True if self != other."""
        return decimojo.biguint.comparison.not_equal(self, other)

    # ===------------------------------------------------------------------=== #
    # Other dunders
    # ===------------------------------------------------------------------=== #

    fn __merge_with__[other_type: __type_of(BigInt)](self) -> BigInt:
        "Merges this BigUInt with a BigInt into a BigInt."
        return BigInt(self)

    fn __merge_with__[other_type: __type_of(BigDecimal)](self) -> BigDecimal:
        "Merges this BigUInt with a BigDecimal into a BigDecimal."
        return BigDecimal(self)

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn add_inplace(mut self, other: Self) raises:
        """Adds `other` to this number in place.
        It is equal to `self += other`.
        See `add_inplace()` for more information.
        """
        decimojo.biguint.arithmetics.add_inplace(self, other)

    @always_inline
    fn floor_divide(self, other: Self) raises -> Self:
        """Returns the result of floor dividing this number by `other`.
        It is equal to `self // other`.
        See `floor_divide()` for more information.
        """
        return decimojo.biguint.arithmetics.floor_divide(self, other)

    @always_inline
    fn truncate_divide(self, other: Self) raises -> Self:
        """Returns the result of truncate dividing this number by `other`.
        It is equal to `self // other`.
        See `truncate_divide()` for more information.
        """
        return decimojo.biguint.arithmetics.truncate_divide(self, other)

    @always_inline
    fn ceil_divide(self, other: Self) raises -> Self:
        """Returns the result of ceil dividing this number by `other`.
        See `ceil_divide()` for more information.
        """
        return decimojo.biguint.arithmetics.ceil_divide(self, other)

    @always_inline
    fn floor_modulo(self, other: Self) raises -> Self:
        """Returns the result of floor modulo this number by `other`.
        See `floor_modulo()` for more information.
        """
        return decimojo.biguint.arithmetics.floor_modulo(self, other)

    @always_inline
    fn truncate_modulo(self, other: Self) raises -> Self:
        """Returns the result of truncate modulo this number by `other`.
        See `truncate_modulo()` for more information.
        """
        return decimojo.biguint.arithmetics.truncate_modulo(self, other)

    @always_inline
    fn ceil_modulo(self, other: Self) raises -> Self:
        """Returns the result of ceil modulo this number by `other`.
        See `ceil_modulo()` for more information.
        """
        return decimojo.biguint.arithmetics.ceil_modulo(self, other)

    @always_inline
    fn divmod(self, other: Self) raises -> Tuple[Self, Self]:
        """Returns the result of divmod this number by `other`.
        See `divmod()` for more information.
        """
        return decimojo.biguint.arithmetics.floor_divide_modulo(self, other)

    @always_inline
    fn floor_divide_inplace_by_2(mut self) raises:
        """Divides this number by 2 in place.
        See `floor_divide_inplace_by_2()` for more information.
        """
        decimojo.biguint.arithmetics.floor_divide_inplace_by_2(self)

    @always_inline
    fn multiply_by_power_of_ten(self, n: Int) -> Self:
        """Returns the result of multiplying this number by 10^n (n>=0).
        See `multiply_by_power_of_ten()` for more information.
        """
        return decimojo.biguint.arithmetics.multiply_by_power_of_ten(self, n)

    @always_inline
    fn multiply_inplace_by_power_of_ten(mut self, n: Int):
        """Multiplies this number in-place by 10^n (n>=0).
        See `multiply_inplace_by_power_of_ten()` for more information.
        """
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_ten(self, n)

    @always_inline
    fn floor_divide_by_power_of_ten(self, n: Int) -> Self:
        """Returns the result of floored dividing this number by 10^n (n>=0).
        It is equal to removing the last n digits of the number.
        See `floor_divide_by_power_of_ten()` for more information.
        """
        return decimojo.biguint.arithmetics.floor_divide_by_power_of_ten(
            self, n
        )

    @always_inline
    fn multiply_inplace_by_power_of_billion(mut self, n: Int):
        """Multiplies a BigUInt in-place by (10^9)^n if n > 0.
        This equals to adding 9n zeros (n words) to the end of the number.

        Args:
            n: The power of 10^9 to multiply by. Should be non-negative.
        """
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
            self, n
        )

    fn power(self, exponent: Int) raises -> Self:
        """Returns the result of raising this number to the power of `exponent`.

        Args:
            exponent: The exponent to raise the number to.

        Returns:
            ValueError: If the exponent is negative.
            ValueError: If the exponent is too large.

        Raises:
            Error: If the exponent is negative.
            Error: If the exponent is too large, e.g., larger than 1_000_000_000.
        """
        if exponent < 0:
            raise Error(
                ValueError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.power(exponent: Int)",
                    message=(
                        "The exponent "
                        + String(exponent)
                        + " is negative.\n"
                        + "Consider using a non-negative exponent."
                    ),
                    previous_error=None,
                )
            )

        if exponent == 0:
            return Self(1)

        if exponent >= 1_000_000_000:
            raise Error(
                ValueError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.power(exponent: Int)",
                    message=(
                        "The exponent "
                        + String(exponent)
                        + " is too large.\n"
                        + "Consider using an exponent below 1_000_000_000."
                    ),
                    previous_error=None,
                )
            )

        var result = Self(1)
        var base = self
        var exp = exponent
        while exp > 0:
            if exp % 2 == 1:
                result = result * base
            base = base * base
            exp //= 2

        return result

    fn power(self, exponent: Self) raises -> Self:
        """Returns the result of raising this number to the power of `exponent`.

        Args:
            exponent: The exponent to raise the number to.

        Raises:
            ValueError: If the exponent is too large.

        Returns:
            The result of raising this number to the power of `exponent`.
        """
        if len(exponent.words) > 1:
            raise Error(
                ValueError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.power(exponent: BigUInt)",
                    message=(
                        "The exponent "
                        + String(exponent)
                        + " is too large.\n"
                        + "Consider using an exponent below 1_000_000_000."
                    ),
                    previous_error=None,
                )
            )
        var exponent_as_int = exponent.to_int()
        return self.power(exponent_as_int)

    fn sqrt(self) -> Self:
        """Returns the square root of this number.

        Returns:
            The square root of x as a BigUInt.

        Notes:

        The square root is the largest integer y such that y * y <= x.
        """
        return decimojo.biguint.exponential.sqrt(self)

    fn isqrt(self) -> Self:
        """Returns the square root of this number.
        It is equal to `sqrt()`.

        Returns:
            The square root of x as a BigUInt.

        Notes:

        The square root is the largest integer y such that y * y <= x.
        """
        return decimojo.biguint.exponential.sqrt(self)

    @always_inline
    fn compare(self, other: Self) -> Int8:
        """Compares the magnitudes of two BigUInts.
        See `compare()` for more information.
        """
        return decimojo.biguint.comparison.compare(self, other)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    fn print_internal_representation(self):
        """Prints the internal representation details of a BigUInt."""
        var string_of_number = self.to_string(line_width=30).split("\n")
        print("\nInternal Representation Details of BigUInt")
        print("----------------------------------------------")
        print("number:         ", end="")
        for i in range(0, len(string_of_number)):
            if i > 0:
                print(" " * 16, end="")
            print(string_of_number[i])
        for i in range(len(self.words)):
            var ndigits = 1
            if i < 10:
                pass
            elif i < 100:
                ndigits = 2
            else:
                ndigits = 3
            print(
                "word ",
                i,
                ":",
                " " * (10 - ndigits),
                String(self.words[i]).rjust(9, fillchar="0"),
                sep="",
            )
        print("----------------------------------------------")

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this BigUInt represents zero."""
        # Yuhao ZHU:
        # BigUInt are desgined to have no leading zero words,
        # so that we only need to check words[0] for zero.
        # If there are leading zero words, it means that we have to loop over
        # all words to check if the number is zero.
        debug_assert[assert_mode="none"](
            (len(self.words) == 1) or (self.words[-1] != 0),
            "biguint.BigUInt.is_zero(): ",
            "BigUInt should not contain leading zero words.",
        )  # 0 should have only one word by design

        return len(self.words) == 1 and self.words._data[] == 0

        # Yuhao ZHU:
        # The following code is commented out because BigUInt is designed
        # to have no leading zero words.
        # We only need to check the first word.
        # They are left here for reference.
        # return (self.words._data[] == 0) and (
        #     memcmp(self.words._data, self.words._data + 1, len(self.words) - 1)
        #     == 0
        # )

    @always_inline
    fn is_zero_in_bounds(self, bounds: Tuple[Int, Int]) -> Bool:
        """Returns True if this BigUInt slice represents zero.

        Args:
            bounds: A tuple of two integers representing the start and end
                indices of the slice to check. Then end index is exclusive.

        Returns:
            True if the slice of this BigUInt represents zero, False otherwise.
        """
        for i in range(bounds[0], bounds[1]):
            if self.words[i] != 0:
                return False
        return True

    @always_inline
    fn is_one(self) -> Bool:
        """Returns True if this BigUInt represents one."""
        if self.words[0] != 1:
            # Least significant word is not 1
            return False
        elif len(self.words) == 1:
            # Least significant word is 1 and there is no other word
            return True
        else:
            # Least significant word is 1 and there are other words
            # Check if all other words are zero
            for i in self.words[1:]:
                if i != 0:
                    return False
            else:
                return True

    @always_inline
    fn is_two(self) -> Bool:
        """Returns True if this BigUInt represents two."""
        if len(self.words) != 2:
            return False
        for i in self.words[1:]:
            if i != 0:
                return False
        return True

    @always_inline
    fn is_power_of_10(x: BigUInt) -> Bool:
        """Check if x is a power of 10."""
        for i in range(len(x.words) - 1):
            if x.words[i] != 0:
                return False
        var word = x.words[len(x.words) - 1]
        if (
            (word == UInt32(1))
            or (word == UInt32(10))
            or (word == UInt32(100))
            or (word == UInt32(1000))
            or (word == UInt32(10_000))
            or (word == UInt32(100_000))
            or (word == UInt32(1_000_000))
            or (word == UInt32(10_000_000))
            or (word == UInt32(100_000_000))
        ):
            return True
        return False

    @always_inline
    fn is_unitialized(self) -> Bool:
        """Returns True if the BigUInt is uninitialized."""
        return len(self.words) == 0

    @always_inline
    fn is_uint64_overflow(self) -> Bool:
        """Returns True if the BigUInt larger than UInt64.MAX."""
        # UInt64.MAX:     18_446_744_073_709_551_615
        # word 0:         709551615
        # word 1:         446744073
        # word 2:         18
        if len(self.words) > 3:
            return True
        elif len(self.words) == 3:
            if self.words[2] > UInt32(18):
                return True
            elif self.words[2] == 18:
                if self.words[1] > UInt32(446744073):
                    return True
                elif self.words[1] == UInt32(446744073):
                    if self.words[0] > UInt32(709551615):
                        return True
        return False

    @always_inline
    fn is_uint128_overflow(self) -> Bool:
        """Returns True if the BigUInt larger than UInt128.MAX."""
        # UInt128.MAX:    340_282_366_920_938_463_463_374_607_431_768_211_455
        # word 0:         768211455
        # word 1:         374607431
        # word 2:         938463463
        # word 3:         282366920
        # word 4:         340
        if len(self.words) > 5:
            return True
        elif len(self.words) == 4:
            if self.words[4] > UInt32(340):
                return True
            elif self.words[4] == UInt32(340):
                if self.words[3] > UInt32(282366920):
                    return True
                elif self.words[3] == UInt32(282366920):
                    if self.words[2] > UInt32(938463463):
                        return True
                    elif self.words[2] == UInt32(938463463):
                        if self.words[1] > UInt32(374607431):
                            return True
                        elif self.words[1] == UInt32(374607431):
                            if self.words[0] > UInt32(768211455):
                                return True
        return False

    @always_inline
    fn ith_digit(self, i: Int) raises -> UInt8:
        """Returns the ith least significant digit of the BigUInt.
        If the index is more than the number of digits, it returns 0.

        Args:
            i: The index of the digit to return. The least significant digit
                is at index 0.

        Returns:
            The ith least significant digit of the BigUInt.

        Raises:
            IndexError: If the index is negative.
        """
        if i < 0:
            raise Error(
                IndexError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.ith_digit(i: Int)",
                    message=(
                        "The index "
                        + String(i)
                        + " is negative.\n"
                        + "Consider using a non-negative index."
                    ),
                    previous_error=None,
                )
            )
        if i >= len(self.words) * 9:
            return 0
        var word_index = i // 9
        var digit_index = i % 9
        if word_index >= len(self.words):
            return 0
        var word = self.words[word_index]
        for _ in range(digit_index):
            word = word // 10
        var digit = word % 10
        return UInt8(digit)

    fn number_of_digits(self) -> Int:
        """Returns the number of digits in the BigUInt.

        Notes:

        Zero has 1 digit.
        """
        if self.is_zero():
            debug_assert(
                len(self.words) == 1, "There are trailing empty words."
            )
            return 1

        var result: Int = (len(self.words) - 1) * 9
        var last_word = self.words[len(self.words) - 1]
        while last_word > 0:
            result += 1
            last_word = last_word // 10
        return result

    fn number_of_words(self) -> Int:
        """Returns the number of words in the BigInt."""
        return len(self.words)

    fn number_of_trailing_zeros(self) -> Int:
        """Returns the number of trailing zeros in the BigUInt."""
        var result: Int = 0
        for i in range(len(self.words)):
            if self.words[i] == 0:
                result += 9
            else:
                var word = self.words[i]
                while word % 10 == 0:
                    result += 1
                    word = word // 10
                break
        return result

    @always_inline
    fn remove_leading_empty_words(mut self):
        """Removes the most significant empty words of a BigUInt.

        Notes:

        The internal representation of a BigUInt is a list of words.
        The most significant empty words are the words that are
        equal to zero and are at the end of the list.

        If the least significant word is zero, we do not remove it.
        """
        if self.words[len(self.words) - 1] != 0:
            # The least significant word is not zero, so we do not remove it
            return
        else:
            var n_empty_words: Int = 0
            for i in range(len(self.words) - 1, 0, -1):
                if self.words[i] == 0:
                    n_empty_words += 1
                else:
                    break
            self.words.shrink(len(self.words) - n_empty_words)

    @always_inline
    fn remove_trailing_digits_with_rounding(
        self,
        ndigits: Int,
        rounding_mode: RoundingMode,
        remove_extra_digit_due_to_rounding: Bool,
    ) raises -> Self:
        """Removes trailing digits from the BigUInt with rounding.

        Args:
            ndigits: The number of digits to remove.
            rounding_mode: The rounding mode to use.
                RoundingMode.ROUND_DOWN: Round down.
                RoundingMode.ROUND_UP: Round up.
                RoundingMode.ROUND_HALF_UP: Round half up.
                RoundingMode.ROUND_HALF_EVEN: Round half even.
            remove_extra_digit_due_to_rounding: If True, remove an trailing
                digit if the rounding mode result in an extra digit.

        Returns:
            The BigUInt with the trailing digits removed.

        Raises:
            ValueError: If the number of digits to remove is negative.

        Notes:

        Rounding can result in an extra digit. Exmaple: remove last 1 digit of
        999 with rounding up results in 100. If
        `remove_extra_digit_due_to_rounding` is True, the result will be 10.
        """
        if ndigits < 0:
            raise Error(
                ValueError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.remove_trailing_digits_with_rounding()",
                    message=(
                        "The number of digits to remove is negative: "
                        + String(ndigits)
                    ),
                    previous_error=None,
                )
            )
        if ndigits == 0:
            return self
        if ndigits > self.number_of_digits():
            raise Error(
                ValueError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.remove_trailing_digits_with_rounding()",
                    message=(
                        "The number of digits to remove is larger than the "
                        "number of digits in the BigUInt: "
                        + String(ndigits)
                        + " > "
                        + String(self.number_of_digits())
                    ),
                    previous_error=None,
                )
            )

        # floor_divide_by_power_of_ten is the same as removing the last n digits
        var result = decimojo.biguint.arithmetics.floor_divide_by_power_of_ten(
            self, ndigits
        )
        var round_up: Bool = False

        if rounding_mode == RoundingMode.ROUND_DOWN:
            pass
        elif rounding_mode == RoundingMode.ROUND_UP:
            if self.number_of_trailing_zeros() < ndigits:
                round_up = True
        elif rounding_mode == RoundingMode.ROUND_HALF_UP:
            if self.ith_digit(ndigits - 1) >= 5:
                round_up = True
        elif rounding_mode == RoundingMode.ROUND_HALF_EVEN:
            var cut_off_digit = self.ith_digit(ndigits - 1)
            if cut_off_digit > 5:
                round_up = True
            elif cut_off_digit < 5:
                pass
            else:  # cut_off_digit == 5
                if self.number_of_trailing_zeros() < ndigits - 1:
                    round_up = True
                else:
                    round_up = self.ith_digit(ndigits) % 2 == 1
        else:
            raise Error(
                ValueError(
                    file="src/decimojo/biguint/biguint.mojo",
                    function="BigUInt.remove_trailing_digits_with_rounding()",
                    message=("Unknown rounding mode: " + String(rounding_mode)),
                    previous_error=None,
                )
            )

        if round_up:
            decimojo.biguint.arithmetics.add_inplace_by_uint32(
                result, UInt32(1)
            )
            # Check whether rounding results in extra digit
            if result.is_power_of_10():
                if remove_extra_digit_due_to_rounding:
                    result = decimojo.biguint.arithmetics.floor_divide_by_power_of_ten(
                        result, 1
                    )
        return result^
