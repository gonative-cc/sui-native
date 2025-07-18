#[test_only]
module btc_parser::output_tests;

use btc_parser::output;
use std::unit_test::assert_eq;

#[test]
fun pkh_script_happy_cases() {
    let output = &output::new(100, x"76a91455ae51684c43435da751ac8d2173b2652eb6410588ac");
    assert_eq!(output.is_P2PHK(), true);
    assert_eq!(output.extract_public_key_hash(), x"55ae51684c43435da751ac8d2173b2652eb64105");
    let output = &output::new(10, x"79a9140fef69f3ac0d9d0473a318ae508875ad0eae3dcc88ac");
    assert_eq!(output.is_P2PHK(), false);
    let output = &output::new(10, x"0014841b80d2cc75f5345c482af96294d04fdd66b2b7");
    assert_eq!(output.is_P2WPHK(), true);
    assert_eq!(output.extract_public_key_hash(), x"841b80d2cc75f5345c482af96294d04fdd66b2b7");
    let output = &output::new(10, x"0101"); // arbitrary script
    assert_eq!(output.is_P2PHK(), false);
    assert_eq!(output.is_P2WPHK(), false);
    assert_eq!(output.extract_public_key_hash(), vector[]);
}

#[test]
fun op_return_script_happy_cases() {
    let data = vector[
        x"6a0b68656c6c6f20776f726c64",
        x"6a",
        x"6a4c0401020304",
        x"6a4d0300010203",
        x"6a4e03000000010203",
    ];
    let expected_result = vector[x"68656c6c6f20776f726c64", x"", x"01020304", x"010203", x"010203"];

    data.length().do!(|i| {
        let o = &output::new(0, data[i]);
        // this return error code at test index fails
        assert_eq!(o.is_op_return(), true);
        assert_eq!(o.op_return(), expected_result[i]);
    });

    let output = &output::new(100, x"76a91455ae51684c43435da751ac8d2173b2652eb6410588ac");
    assert_eq!(output.is_op_return(), false);
}
