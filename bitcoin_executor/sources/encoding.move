// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::btc_encoding;

use btc_parser::vector_utils;

#[test_only]
use std::unit_test::assert_eq;

#[error]
const EDerIntParsing: vector<u8> = b"Error parsing DER to Int";
#[error]
const EBtcSigParsing: vector<u8> = b"Error parsing bitcoin signature";

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
    let expected_r = x"d8a05a72f026dd543a287164d79f496901e8678866a23c9830695f5101add608";
    let expected_s = x"236272d43be9da20ef7a94925109190813402211154201941343998116181992";
    let mut expected_rs = expected_r;
    expected_rs.append(expected_s);

    let (r_and_s_bytes, sighash_flag) = parse_btc_sig(&mut full_sig_hex);
    assert_eq!(r_and_s_bytes, expected_rs);
    assert_eq!(sighash_flag, 0x01);
}

#[test]
fun test_parse_btc_sig_another_valid() {
    let mut full_sig_hex =
        x"3044022010720e86c81bc5ca0593d2a3029c090a6e358e01c7d7d37f77d47b05c3404c0e022012009144c8ef2c4fe5c8164fcc5602db88b549ee8b7f57ac217294bd593be2d001";
    let expected_r = x"10720E86C81BC5CA0593D2A3029C090A6E358E01C7D7D37F77D47B05C3404C0E";
    let expected_s = x"12009144C8EF2C4FE5C8164FCC5602DB88B549EE8B7F57AC217294BD593BE2D0";
    let mut expected_rs = expected_r;
    expected_rs.append(expected_s);

    let (r_and_s_bytes, sighash_flag) = parse_btc_sig(&mut full_sig_hex);
    assert_eq!(r_and_s_bytes, expected_rs);
    assert_eq!(sighash_flag, 0x01);
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
