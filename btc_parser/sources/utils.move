module btc_parser::utils;
use std::u64::do;
use std::hash::sha2_256;

#[error]
const EOutOfBounds: vector<u8> = b"Slice out of bounds";
#[error]
const EOverflowVector: vector<u8> = b"Can't covert vector to u64 b/c overflow";

/// Converts vector bytes in the little-endian form to a u64 integer
public fun le_bytes_to_u64(v: vector<u8>): u64 {
    assert!(v.length() <= 8, EOverflowVector);
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


/// Returns slice of a vector for a given range [start_index ,end_index).
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
