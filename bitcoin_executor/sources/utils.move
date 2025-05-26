module bitcoin_executor::utils;

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
