// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::utils;

use std::u64::do;

#[test_only]
use std::unit_test::assert_eq;

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

public fun vector_true(): vector<u8> { vector[0x01] }

public fun vector_false(): vector<u8> { vector[] }

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

/// Prepends the VarInt encoding of the script len to the script.
public fun script_to_var_bytes(script: &vector<u8>): vector<u8> {
    let len = script.length();
    let mut result = u64_to_varint_bytes(len);
    result.append(*script);
    result
}

/// Returns a vector with 32 zero bytes.
public fun zerohash_32bytes(): vector<u8> {
    vector::tabulate!(32, |_| 0)
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

#[test]
fun test_zerohash_32bytes() {
    let expected = x"0000000000000000000000000000000000000000000000000000000000000000";
    assert_eq!(zerohash_32bytes(), expected);
    assert_eq!(zerohash_32bytes().length(), 32);
}
