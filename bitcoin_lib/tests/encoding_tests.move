// SPDX-License-Identifier: MPL-2.0

#[test_only]
module bitcoin_lib::encoding_tests;

use bitcoin_lib::encoding::{
    u32_to_le_bytes,
    u64_to_le_bytes,
    u64_to_be_bytes,
    u64_to_varint_bytes,
    big_endian_to_u256,
    big_endian_from_u256
};
use std::unit_test::assert_eq;

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
fun test_u64_to_be_bytes() {
    assert_eq!(u64_to_be_bytes(0x123456789abcdef0), x"123456789abcdef0");
    assert_eq!(u64_to_be_bytes(1), x"0000000000000001");
    assert_eq!(u64_to_be_bytes(0), x"0000000000000000");
    assert_eq!(u64_to_be_bytes(0xFFFFFFFFFFFFFFFF), x"FFFFFFFFFFFFFFFF");
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

#[test]
fun test_big_endian_conversions() {
    // Define test pairs: (number, expected_big_endian_bytes)
    let test_numbers = vector[
        0,
        1,
        10,
        255,
        256,
        65535,
        65536,
        16777215,
        16777216,
        4294967295,
        4294967296,
        0x12345678,
        0x123456789abcdef0,
        0x8000000000000000000000000000000000000000000000000000000000000000,
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
    ];

    let test_bytes = vector[
        x"00",
        x"01",
        x"0a",
        x"ff",
        x"0100",
        x"ffff",
        x"010000",
        x"ffffff",
        x"01000000",
        x"ffffffff",
        x"0100000000",
        x"12345678",
        x"123456789abcdef0",
        x"8000000000000000000000000000000000000000000000000000000000000000",
        x"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    ];

    // Verify arrays have same length
    assert_eq!(test_numbers.length(), test_bytes.length());

    test_numbers.length().do!(|i| {
        let number = test_numbers[i];
        let bytes = test_bytes[i];

        // Test number to bytes conversion
        assert_eq!(big_endian_from_u256(number), bytes);

        // Test bytes to number conversion
        assert_eq!(big_endian_to_u256(bytes), number);
    });
}
