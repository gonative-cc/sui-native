// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::utils;

use std::hash::sha2_256;
use std::u64::do;

#[test_only]
use std::unit_test::assert_eq;

#[error]
const EOutOfBounds: vector<u8> = b"Slice out of bounds";

/// Converts u64 into the CScriptNum byte vector format.
/// This is the format expected to be pushed onto the stack.
/// https://github.com/bitcoin/bitcoin/blob/87ec923d3a7af7b30613174b41c6fb11671df466/src/script/script.h#L349
public(package) fun u64_to_cscriptnum(n: u64): vector<u8> {
    let mut result_bytes = vector::empty<u8>();
    if (n == 0) {
        return result_bytes // 0 is represented by empty vector
    };

    let mut n = n;
    // convert to little endian
    while (n > 0) {
        result_bytes.push_back((n & 0xff) as u8);
        n = n >> 8;
    };

    // padding
    if (result_bytes.length() > 0) {
        let last_index = result_bytes.length() -1;
        let last_byte = *result_bytes.borrow(last_index);
        if ((last_byte & 0x80) != 0) {
            result_bytes.push_back(0x00);
        }
    };
    result_bytes
}

public(package) fun le_vec_to_number(v: vector<u8>): u64 {
    let mut number: u64 = 0;
    v.length().do!(|i| {
        number = number + ((v[i] as u64) * ((1 as u64) << ((i as u8) * 8)) as u64)
    });
    number
}

public fun vector_true(): vector<u8> { vector[0x01] }

public fun vector_false(): vector<u8> { vector[] }

public fun vector_slice<T: copy + drop>(
    source: &vector<T>,
    start_index: u64,
    end_index: u64,
): vector<T> {
    assert!(start_index <= end_index, EOutOfBounds);
    assert!(end_index <= source.length(), EOutOfBounds);

    let mut slice = vector::empty<T>();
    let mut i = start_index;
    while (i < end_index) {
        slice.push_back(source[i]);
        i = i + 1;
    };
    slice
}

/// Encodes a u64 into VarInt format.
/// Adapted from go_native/move_spv_light_client
public fun u64_to_varint_bytes(n: u64): vector<u8> {
    let mut ans = vector::empty<u8>();
    let mut n = n;
    if (n <= 252) {
        ans.push_back(n as u8);
    } else if (n <= 65535) {
        ans.push_back(0xfd);
        do!(2, |_i| {
            ans.push_back((n & 0xff) as u8);
            n = n >> 8;
        });
    } else if (n <= 4294967295) {
        ans.push_back(0xfe);
        do!(4, |_i| {
            ans.push_back((n & 0xff) as u8);
            n = n >> 8;
        });
    } else {
        ans.push_back(0xff);
        do!(8, |_i| {
            ans.push_back((n & 0xff) as u8);
            n = n >> 8;
        });
    };
    ans
}

/// Converts a u32 integer to a 4-byte little-endian vector<u8>.
public fun u32_to_le_bytes(val: u32): vector<u8> {
    let mut bytes = vector::empty<u8>();
    bytes.push_back(((val >> 0) & 0xFF) as u8);
    bytes.push_back(((val >> 8) & 0xFF) as u8);
    bytes.push_back(((val >> 16) & 0xFF) as u8);
    bytes.push_back(((val >> 24) & 0xFF) as u8);
    bytes
}

/// Converts a u64 integer to an 8-byte little-endian vector<u8>.
public fun u64_to_le_bytes(val: u64): vector<u8> {
    let mut bytes = vector::empty<u8>();
    bytes.push_back(((val >> 0) & 0xFF) as u8);
    bytes.push_back(((val >> 8) & 0xFF) as u8);
    bytes.push_back(((val >> 16) & 0xFF) as u8);
    bytes.push_back(((val >> 24) & 0xFF) as u8);
    bytes.push_back(((val >> 32) & 0xFF) as u8);
    bytes.push_back(((val >> 40) & 0xFF) as u8);
    bytes.push_back(((val >> 48) & 0xFF) as u8);
    bytes.push_back(((val >> 56) & 0xFF) as u8);
    bytes
}

/// Prepends the VarInt encoding of the script len to the script.
public fun script_to_var_bytes(script: &vector<u8>): vector<u8> {
    let len = script.length();
    let mut result = u64_to_varint_bytes(len);
    result.append(*script);
    result
}

/// Returns a vector with 32 zero bytes.
public fun zerohash_32bytes(): vector<u8> {
    let mut zeros = vector::empty<u8>();
    let mut i = 0;
    while (i < 32) {
        zeros.push_back(0x00);
        i = i + 1;
    };
    zeros
}

/// Computes sha2_256(sha2_256(data)).
public fun hash256(data: vector<u8>): vector<u8> {
    sha2_256(sha2_256(data))
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
fun test_script_to_var_bytes() {
    assert_eq!(1, 1)
    //TODO: add test for it
}

#[test]
fun test_u64_to_cscriptnum() {
    assert_eq!(u64_to_cscriptnum(0), vector[]); // 0 -> []
    assert_eq!(u64_to_cscriptnum(127), vector[0x7f]); // 127 -> [0x7f]
    assert_eq!(u64_to_cscriptnum(128), vector[0x80, 0x00]); // 128 -> [0x80, 0x00] padding
    assert_eq!(u64_to_cscriptnum(255), vector[0xff, 0x00]); // 255 -> [0xff, 0x00] padding
    assert_eq!(u64_to_cscriptnum(256), vector[0x00, 0x01]); // 256 -> [0x00, 0x01]
    assert_eq!(u64_to_cscriptnum(520), vector[0x08, 0x02]); // 520 -> [0x08, 0x02]
}

//TODO: add more tests for slice
#[test]
fun test_vector_slice() {
    let v = vector[1, 2, 3, 4, 5];
    assert_eq!(vector_slice(&v, 1, 4), vector[2, 3, 4]); // [1, 2, 3, 4, 5] -> [2, 3, 4]
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
fun test_zerohash_32bytes() {
    let expected = x"0000000000000000000000000000000000000000000000000000000000000000";
    assert_eq!(zerohash_32bytes(), expected);
    assert_eq!(zerohash_32bytes().length(), 32);
}

#[test]
fun test_hash256() {
    let data_to_hash = x"0011";
    let expected = x"cbcf27657ceb69162a9f5153c6956d6fdd81f71d7bc0bca243bff54b405e4410";
    assert_eq!(hash256(data_to_hash), expected);
}
