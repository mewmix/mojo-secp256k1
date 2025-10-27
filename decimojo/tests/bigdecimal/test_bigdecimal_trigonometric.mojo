"""
Test BigDecimal trigonometric functions
"""

from python import Python
import testing

from decimojo import BDec
from decimojo.tests import TestCase, parse_file, load_test_cases

alias file_path = "tests/bigdecimal/test_data/bigdecimal_trigonometric.toml"


fn run_test[
    func: fn (BDec, Int) raises -> BDec
](toml: tomlmojo.parser.TOMLDocument, table_name: String, msg: String) raises:
    """Run a specific test case from the TOML document."""
    print("------------------------------------------------------")
    print("Testing BigDecimal ", msg, "...", sep="")
    var test_cases = load_test_cases(toml, table_name)
    for test_case in test_cases:
        try:
            var result = func(BDec(test_case.a), 50)
            testing.assert_equal(
                lhs=result,
                rhs=BDec(test_case.expected),
                msg=test_case.description,
            )
        except e:
            print(test_case.description)


fn test_bigdecimal_trignometric() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path)

    run_test[func = decimojo.bigdecimal.trigonometric.sin](
        toml,
        "sin_tests",
        "sin",
    )
    run_test[func = decimojo.bigdecimal.trigonometric.cos](
        toml,
        "cos_tests",
        "cos",
    )
    run_test[func = decimojo.bigdecimal.trigonometric.tan](
        toml,
        "tan_tests",
        "tan",
    )
    run_test[func = decimojo.bigdecimal.trigonometric.cot](
        toml,
        "cot_tests",
        "cot",
    )
    run_test[func = decimojo.bigdecimal.trigonometric.arctan](
        toml,
        "arctan_tests",
        "arctan",
    )


fn main() raises:
    print("Running BigDecimal trigonometric tests")

    # Run all tests
    test_bigdecimal_trignometric()

    print("All BigDecimal trigonometric tests passed!")
