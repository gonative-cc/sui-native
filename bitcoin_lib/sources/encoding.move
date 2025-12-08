// SPDX-License-Identifier: MPL-2.0

module bitcoin_lib::encoding;

use bitcoin_lib::vector_utils;
use std::u64::do;

#[test_only]
use std::unit_test::assert_eq;

#[error]
const EDerIntParsing: vector<u8> = b"Error parsing DER to Int";
#[error]
const EBtcSigParsing: vector<u8> = b"Error parsing bitcoin signature";

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

/// Converts u64 into the CScriptNum byte vector format.
/// This is the format expected to be pushed onto the stack.
/// https://github.com/bitcoin/bitcoin/blob/87ec923d3a7af7b30613174b41c6fb11671df466/src/script/script.h#L349
public fun u64_to_cscriptnum(n: u64): vector<u8> {
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

/// Parses a DER-encoded positvie integer value (r or s) to 32-byte vector
fun der_int_to_32_bytes(val_bytes: &vector<u8>): vector<u8> {
    let len = val_bytes.length();

    assert!(len > 0 && len <= 33, EDerIntParsing);

    let offset;
    let mut value_len = 32;
    if (len == 33) {
        // prefix 0x00
        assert!(val_bytes[0] == 0x00, EDerIntParsing);
        assert!(val_bytes[1] & 0x80 != 0, EDerIntParsing);
        // check if MSB od second byte is 1, else wrong padding
        offset = 1; // skip 0x00
    } else if (len == 32) {
        // no prefix
        offset = 0;
    } else {
        // padding needed
        assert!(!(val_bytes[0] == 0x00 && len > 1), EDerIntParsing); // wrong leading 0x00 for short number
        offset = 0;
        value_len = len;
    };
    let mut result_32_bytes = vector::empty<u8>();
    let num_padding_zeros = 32 - value_len;

    let mut i = 0;
    while (i < num_padding_zeros) {
        result_32_bytes.push_back(0x00);
        i = i + 1;
    };

    i = 0;
    while (i < value_len) {
        result_32_bytes.push_back(val_bytes[offset+i]);
        i = i + 1;
    };

    result_32_bytes
}

/// Parses a single DER-encoded INT from der_bytes at the current cursor and modifies the cursor.
fun parse_der_encoded_int_value(
    der_bytes: &vector<u8>,
    cursor: &mut u64,
    der_len: u64,
): vector<u8> {
    assert!(*cursor < der_len && der_bytes[*cursor] == 0x02, EBtcSigParsing);
    *cursor = *cursor + 1;
    assert!(*cursor < der_len, EBtcSigParsing);

    let component_len = (der_bytes[*cursor] as u64);
    *cursor = *cursor + 1;
    assert!(component_len > 0 && *cursor + component_len <= der_len, EBtcSigParsing);
    let value_der_bytes = vector_utils::vector_slice(
        der_bytes,
        *cursor,
        *cursor + component_len,
    );
    *cursor = *cursor + component_len;

    value_der_bytes
}

/// Parses a DER encoded Bitcoin signature (r,s + sighash flag)
/// Returns a tuple containing the 64-byte concat(r,s) and sighash_flag.
public fun parse_btc_sig(full_sig_from_stack: &mut vector<u8>): (vector<u8>, u8) {
    // TODO: use reader module
    let total_len = full_sig_from_stack.length();
    assert!(total_len >= 8 && total_len <= 73, EBtcSigParsing);

    let sighash_flag = full_sig_from_stack.pop_back();
    let der_bytes = full_sig_from_stack;
    let der_len = der_bytes.length();

    assert!(der_len > 0, EBtcSigParsing);

    let mut cursor = 0;

    // SEQUENCE tag (0x30)
    assert!(cursor < der_len && der_bytes[cursor] == 0x30, EBtcSigParsing);
    cursor = cursor + 1;
    assert!(cursor < der_len, EBtcSigParsing);

    let seq_len = (der_bytes[cursor] as u64);
    cursor = cursor + 1;
    assert!(seq_len == der_len - cursor, EBtcSigParsing);

    // Parse R
    let r_value_der = parse_der_encoded_int_value(der_bytes, &mut cursor, der_len);
    let r_32_bytes = der_int_to_32_bytes(&r_value_der);

    // Parse S
    let s_value_der = parse_der_encoded_int_value(der_bytes, &mut cursor, der_len);
    let s_32_bytes = der_int_to_32_bytes(&s_value_der);

    assert!(cursor == der_len, EBtcSigParsing);

    // concat (r,s)
    let mut r_and_s_bytes = r_32_bytes;
    r_and_s_bytes.append(s_32_bytes);

    (r_and_s_bytes, sighash_flag)
}

/// covert litle endian bytes to u256
public fun big_endian_to_u256(bytes: vector<u8>): u256 {
    let mut number: u256 = 0;
    let mut b = bytes;
    b.reverse();
    b.length().do!(|i| {
        number = number + ((b[i] as u256) << ((i * 8) as u8));
    });
    number
}

public fun bigendian_from_u256(number: u256): vector<u8> {
    let mut n = number;
    let mut b = vector[];
    while (n > 0) {
        b.push_back((n & 0xFF) as u8);
        n = n >> 8;
    };
    b.reverse();
    b
}

/// BIP-0146 https://github.com/bitcoin/bips/blob/master/bip-0146.mediawiki
/// (r, s) is ECDSA signarure, s MUST:
/// 0x01 <= s <= 0x7FFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 5D576E73 57A4501D DFE92F46 681B20A0
/// (r, s) use big endian format
public fun sig_low_s(sig_s: vector<u8>): vector<u8> {
    let mut s_num = big_endian_to_u256(s);
    let half_n = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;
    let n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
    if (s_num > half_n) {
        s_num = n - s_num;
    };
    bigendian_from_u256(s_num)
}

/// Fomat raw singature (r, s) to btc ECDSA format,
/// Ref: https://learnmeabitcoin.com/technical/keys/signature/
public fun der_encode_signature(signature: vector<u8>, signature_hash_type: u8): vector<u8> {
    assert!(signature.length() == 64);
    let mut r = vector_utils::vector_slice(&signature, 0, 32);
    let mut s = vector_utils::vector_slice(&signature, 32, 64);

    if (r[0] >= 0x80) {
        r.insert(0x00, 0);
    };

    s = low_s(s);
    if (s[0] >= 0x80) {
        s.insert(0x00, 0);
    };

    let mut res = vector::empty();

    res.push_back(0x30);
    // data = 0x02 || r.length() || r || 0x02 || s.length() || s
    // so total len = 4 + r.length() + r.length()
    res.push_back(4 + (r.length() as u8) + (s.length() as u8));
    res.push_back(0x02);
    res.push_back(r.length() as u8);
    res.append(r);
    res.push_back(0x02);
    res.push_back(s.length() as u8);
    res.append(s);
    res.push_back(signature_hash_type);
    res
}

#[test]
fun test_der_int_to_32_bytes_positive_no_padding() {
    let r_val = x"7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"; // 32 bytes, MSB is 0
    let result = der_int_to_32_bytes(&r_val);
    assert_eq!(result, r_val);
}

#[test]
fun test_der_int_to_32_bytes_positive_with_padding() {
    let r_der_val = x"008000000000000000000000000000000000000000000000000000000000000000"; // 33 bytes
    let expected_r = x"8000000000000000000000000000000000000000000000000000000000000000"; // 32 bytes
    let result = der_int_to_32_bytes(&r_der_val);
    assert_eq!(result, expected_r);
}

#[test]
fun test_der_int_to_32_bytes_shorter_needs_padding() {
    let r_der_val = x"012345"; // 3 bytes
    let expected_r_32 = x"0000000000000000000000000000000000000000000000000000000000012345";
    let result = der_int_to_32_bytes(&r_der_val);
    assert_eq!(result, expected_r_32);
}

#[test, expected_failure(abort_code = EDerIntParsing)]
fun der_int_to_32_bytes_too_long() {
    let r_der_val = x"00010000000000000000000000000000000000000000000000000000000000000000"; // 34 bytes
    der_int_to_32_bytes(&r_der_val);
}

#[test, expected_failure(abort_code = EDerIntParsing)]
fun der_int_to_32_bytes_invalid_leading_zero() {
    let r_der_val = x"007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    der_int_to_32_bytes(&r_der_val);
}

#[test, expected_failure(abort_code = EDerIntParsing)]
fun der_int_to_32_bytes_integer_empty() {
    der_int_to_32_bytes(&vector[]);
}

#[test]
fun test_parse_btc_sig_valid() {
    let mut full_sig_hex =
        x"3045022100d8a05a72f026dd543a287164d79f496901e8678866a23c9830695f5101add6080220236272d43be9da20ef7a9492510919081340221115420194134399811618199201";
    let full_sig = full_sig_hex;
    let expected_r = x"d8a05a72f026dd543a287164d79f496901e8678866a23c9830695f5101add608";
    let expected_s = x"236272d43be9da20ef7a94925109190813402211154201941343998116181992";
    let mut expected_rs = expected_r;
    expected_rs.append(expected_s);

    let (r_and_s_bytes, sighash_flag) = parse_btc_sig(&mut full_sig_hex);
    assert_eq!(r_and_s_bytes, expected_rs);
    assert_eq!(sighash_flag, 0x01);
    assert_eq!(der_encode_signature(r_and_s_bytes, sighash_flag), full_sig);
}

#[test]
fun test_parse_btc_sig_another_valid() {
    let mut full_sig_hex =
        x"3044022010720e86c81bc5ca0593d2a3029c090a6e358e01c7d7d37f77d47b05c3404c0e022012009144c8ef2c4fe5c8164fcc5602db88b549ee8b7f57ac217294bd593be2d001";
    let full_sig = full_sig_hex;
    let expected_r = x"10720E86C81BC5CA0593D2A3029C090A6E358E01C7D7D37F77D47B05C3404C0E";
    let expected_s = x"12009144C8EF2C4FE5C8164FCC5602DB88B549EE8B7F57AC217294BD593BE2D0";
    let mut expected_rs = expected_r;
    expected_rs.append(expected_s);

    let (r_and_s_bytes, sighash_flag) = parse_btc_sig(&mut full_sig_hex);
    assert_eq!(r_and_s_bytes, expected_rs);
    assert_eq!(sighash_flag, 0x01);
    assert_eq!(der_encode_signature(r_and_s_bytes, sighash_flag), full_sig);
}

#[test, expected_failure(abort_code = EBtcSigParsing)]
fun test_parse_btc_sig_invalid_tag() {
    let mut full_sig_hex = x"3145022001"; // Invalid sequence tag 0x31
    parse_btc_sig(&mut full_sig_hex);
}

#[test, expected_failure(abort_code = EBtcSigParsing)]
fun test_parse_btc_sig_too_short() {
    let mut full_sig_hex = x"300502010002010001"; // Only 7 bytes DER + 1 sighash
    parse_btc_sig(&mut full_sig_hex);
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
