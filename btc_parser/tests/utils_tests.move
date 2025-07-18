#[test_only]
module btc_parser::utils_tests;

use btc_parser::utils::{
    vector_slice,
    u32_to_le_bytes,
    u64_to_le_bytes,
    u64_to_varint_bytes,
    hash256
};
use std::unit_test::assert_eq;

// TODO: add more tests for slice
#[test]
fun test_vector_slice() {
    let v = vector[1, 2, 3, 4, 5];
    assert_eq!(vector_slice(&v, 1, 4), vector[2, 3, 4]); // [1, 2, 3, 4, 5] -> [2, 3, 4]
}

#[test]
fun test_hash256() {
    let data_to_hash = x"0011";
    let expected = x"cbcf27657ceb69162a9f5153c6956d6fdd81f71d7bc0bca243bff54b405e4410";
    assert_eq!(hash256(data_to_hash), expected);
}

#[test]
fun test_u32_to_le_bytes() {
    assert_eq!(u32_to_le_bytes(0x12345678), x"78563412");
    assert_eq!(u32_to_le_bytes(1), x"01000000");
}

#[test]
fun test_u64_to_le_bytes() {
    assert_eq!(u64_to_le_bytes(0x123456789abcdef0), x"f0debc9a78563412");
    assert_eq!(u64_to_le_bytes(1), x"0100000000000000");
}

#[test]
fun test_u64_to_varint_bytes() {
    assert_eq!(u64_to_varint_bytes(0), x"00");
    assert_eq!(u64_to_varint_bytes(10), x"0a");
    assert_eq!(u64_to_varint_bytes(252), x"fc");
    assert_eq!(u64_to_varint_bytes(253), x"fdfd00");
    assert_eq!(u64_to_varint_bytes(1000), x"fde803");
    assert_eq!(u64_to_varint_bytes(65535), x"fdffff");
    assert_eq!(u64_to_varint_bytes(65536), x"fe00000100");
    assert_eq!(u64_to_varint_bytes(4294967295), x"feffffffff");
    assert_eq!(u64_to_varint_bytes(4294967296), x"ff0000000001000000");
}
