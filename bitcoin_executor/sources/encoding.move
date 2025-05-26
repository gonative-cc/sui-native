module bitcoin_executor::encoding;

use bitcoin_executor::utils;

#[test_only]
use std::unit_test::assert_eq;

#[error]
const EDerIntParsing: vector<u8> = b"Error while parsing DER to Int";
#[error]
const EBtcSigParsing: vector<u8> = b"Error while parsing bitcoin signature";

/// Represents parsed Bitcoin ECDSA signature.
public struct ParsedSignature has copy, drop {
    r_and_s_64_bytes: vector<u8>, // concat(r,s)
    sighash_flag: u8,
}

/// Parses a DER-encoded positvie integer value (r or s) to 32-byte vecto
fun der_int_to_32_bytes(val_bytes: &vector<u8>): vector<u8> {
    let len = val_bytes.length();

    assert!(len > 0 && len <= 33, EDerIntParsing);

    let offset;
    let value_len;

    if (len == 33) {
        // prefix 0x00
        assert!(val_bytes[0] == 0x00, EDerIntParsing);
        assert!(val_bytes[1] & 0x80 != 0, EDerIntParsing);
        // check if MSB od second byte is 1, else wrong padding
        offset = 1; // skip 0x00
        value_len = 32;
    } else if (len < 32) {
        // padding needed
        assert!(!(val_bytes[0] == 0x00 && len > 1), EDerIntParsing); // wrong leading 0x00 for short number
        offset = 0;
        value_len = len;
    } else {
        // len == 32
        // no prefix
        offset = 0;
        value_len = 32;
    };
    let mut result_32_bytes = vector::empty<u8>();
    let num_padding_zeros = 32 - value_len;

    let mut i = 0;
    while (i < num_padding_zeros) {
        result_32_bytes.push_back(0x00);
        i = i + 1;
    };

    let mut j = 0;
    while (j < value_len) {
        result_32_bytes.push_back(val_bytes[offset+j]);
        j = j + 1;
    };

    result_32_bytes
}

/// Parses a DER encoded Bitcoin signature (r,s + sighash flag)
/// Returns a ParsedSignature containing the 64-byte concat(r,s) and sighash_flag.
public fun parse_bitcoin_signature(full_sig_from_stack: &mut vector<u8>): ParsedSignature {
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
    assert!(cursor < der_len && der_bytes[cursor] == 0x02, EBtcSigParsing);
    cursor = cursor + 1;
    assert!(cursor < der_len, EBtcSigParsing);

    let r_len = (der_bytes[cursor] as u64);
    cursor = cursor + 1;
    assert!(cursor + r_len <= der_len, EBtcSigParsing); //make sure R value dosent extend DER bytes
    let r_value_der = utils::vector_slice(der_bytes, cursor, cursor + r_len);
    cursor = cursor + r_len;

    let r_32_bytes = der_int_to_32_bytes(&r_value_der);

    // Parse S
    assert!(cursor < der_len && der_bytes[cursor] == 0x02, EBtcSigParsing);
    cursor = cursor + 1;
    assert!(cursor < der_len, EBtcSigParsing);

    let s_len = (der_bytes[cursor] as u64);
    cursor = cursor + 1;
    assert!(cursor + s_len <= der_len, EBtcSigParsing); //make sure S value dosent extend DER bytes
    let s_value_der = utils::vector_slice(der_bytes, cursor, cursor + s_len);
    cursor = cursor + s_len;

    let s_32_bytes = der_int_to_32_bytes(&s_value_der);

    assert!(cursor == der_len, EBtcSigParsing);

    // concat (r,s)
    let mut r_and_s_64_bytes = r_32_bytes;
    r_and_s_64_bytes.append(s_32_bytes);

    ParsedSignature {
        r_and_s_64_bytes,
        sighash_flag,
    }
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
fun test_parse_bitcoin_signature_valid() {
    let mut full_sig_hex =
        x"3045022100d8a05a72f026dd543a287164d79f496901e8678866a23c9830695f5101add6080220236272d43be9da20ef7a9492510919081340221115420194134399811618199201";
    let expected_r = x"d8a05a72f026dd543a287164d79f496901e8678866a23c9830695f5101add608";
    let expected_s = x"236272d43be9da20ef7a94925109190813402211154201941343998116181992";
    let mut expected_rs = expected_r;
    expected_rs.append(expected_s);

    let parsed = parse_bitcoin_signature(&mut full_sig_hex);
    assert_eq!(parsed.r_and_s_64_bytes, expected_rs);
    assert_eq!(parsed.sighash_flag, 0x01);
}

#[test]
fun test_parse_bitcoin_signature_another_valid() {
    let mut full_sig_hex =
        x"3044022010720e86c81bc5ca0593d2a3029c090a6e358e01c7d7d37f77d47b05c3404c0e022012009144c8ef2c4fe5c8164fcc5602db88b549ee8b7f57ac217294bd593be2d001";
    let expected_r = x"10720E86C81BC5CA0593D2A3029C090A6E358E01C7D7D37F77D47B05C3404C0E";
    let expected_s = x"12009144C8EF2C4FE5C8164FCC5602DB88B549EE8B7F57AC217294BD593BE2D0";
    let mut expected_rs = expected_r;
    expected_rs.append(expected_s);

    let parsed = parse_bitcoin_signature(&mut full_sig_hex);
    assert_eq!(parsed.r_and_s_64_bytes, expected_rs);
    assert_eq!(parsed.sighash_flag, 0x01);
}

#[test, expected_failure(abort_code = EBtcSigParsing)]
fun test_parse_bitcoin_signature_invalid_tag() {
    let mut full_sig_hex = x"3145022001"; // Invalid sequence tag 0x31
    parse_bitcoin_signature(&mut full_sig_hex);
}

#[test, expected_failure(abort_code = EBtcSigParsing)]
fun test_parse_bitcoin_signature_too_short() {
    let mut full_sig_hex = x"300502010002010001"; // Only 7 bytes DER + 1 sighash
    parse_bitcoin_signature(&mut full_sig_hex);
}
