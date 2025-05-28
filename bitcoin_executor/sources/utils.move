module bitcoin_executor::utils;

#[test_only]
use std::unit_test::assert_eq;
use std::u64::do;

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

public(package) fun LEtoNumber(v: vector<u8>) : u64{
    let mut number: u64 = 0;
    v.length().do!(|i| {
        number = number + (v[i] * (1 << ((i as u8) * 8)) as u64)
    });
    number
}


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

#[test]
fun test_u64_to_cscriptnum() {
    assert_eq!(u64_to_cscriptnum(0), vector[]); // 0 -> []
    assert_eq!(u64_to_cscriptnum(127), vector[0x7f]); // 127 -> [0x7f]
    assert_eq!(u64_to_cscriptnum(128), vector[0x80, 0x00]); // 128 -> [0x80, 0x00] padding
    assert_eq!(u64_to_cscriptnum(255), vector[0xff, 0x00]); // 255 -> [0xff, 0x00] padding
    assert_eq!(u64_to_cscriptnum(256), vector[0x00, 0x01]); // 256 -> [0x00, 0x01]
    assert_eq!(u64_to_cscriptnum(520), vector[0x08, 0x02]); // 520 -> [0x08, 0x02]
}
