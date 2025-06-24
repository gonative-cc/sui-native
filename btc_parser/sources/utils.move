module btc_parser::utils;
use std::u64::do;
use std::hash::sha2_256;


#[test_only]
use std::unit_test::assert_eq;

#[error]
const EOutOfBounds: vector<u8> = b"Slice out of bounds";

/// covert vector bytes in little endian to number
public fun le_bytes_to_number(v: vector<u8>): u64 {
    let mut number = 0;
    v.length().do!(|i| {
        number = number + ((v[i] as u64) * ((1 as u64) << ((i as u8) * 8)) as u64)
    });
    number
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

/// Computes sha2_256(sha2_256(data)).
public fun hash256(data: vector<u8>): vector<u8> {
    sha2_256(sha2_256(data))
}


// TODO this is overlap with slice function in sui-bitcoin-spv
/// Get slice from [start,end] in source.
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
