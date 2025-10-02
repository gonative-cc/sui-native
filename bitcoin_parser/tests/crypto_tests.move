// SPDX-License-Identifier: MPL-2.0

#[test_only]
module bitcoin_parser::crypto_tests;

use bitcoin_parser::crypto::hash256;
use std::unit_test::assert_eq;

#[test]
fun test_hash256() {
    let data_to_hash = x"0011";
    let expected = x"cbcf27657ceb69162a9f5153c6956d6fdd81f71d7bc0bca243bff54b405e4410";
    assert_eq!(hash256(data_to_hash), expected);
}
