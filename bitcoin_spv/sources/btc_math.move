// SPDX-License-Identifier: MPL-2.0

module bitcoin_spv::btc_math;

#[test_only]
use std::unit_test::assert_eq;

/// === Errors ===
#[error]
const EInvalidLength: vector<u8> = b"The input vector has an invalid length";

/// Converts 32 bytes in little endian format to u256 number.
public fun to_u256(v: vector<u8>): u256 {
    assert!(v.length() == 32, EInvalidLength);
    let mut ans = 0u256;
    let mut i = 0;

    while (i < 32) {
        ans = ans +  ((v[i] as u256)  << (i * 8 as u8));
        i = i + 1;
    };
    ans
}

/// number of bytes to represent number.
fun bytes_of(number: u256): u8 {
    let mut b: u8 = 255;
    while (number & (1 << b) == 0 && b > 0) {
        b = b - 1;
    };
    // Follow logic in bitcoin core
    ((b as u32) / 8 + 1) as u8
}

/// Returns last 32 bits of a number.
fun get_last_32_bits(number: u256): u32 {
    (number & 0xffffffff) as u32
}

/// target => bits conversion function.
/// target is the number you need to get below to mine a block - it defines the difficulty.
/// The bits field contains a compact representation of the target.
/// format of bits = <1 byte for exponent><3 bytes for coefficient>
/// target = coefficient * 2^ (coefficient - 3) (note: 3 = bytes length of the coefficient).
/// Caution:
///    The first significant byte for the coefficient must be below 80. If it's not, you have to take the preceding 00 as the first byte.
/// More & examples: https://learnmeabitcoin.com/technical/block/bits.
public fun target_to_bits(target: u256): u32 {
    // TODO: Handle case nagative target?
    // I checked bitcoin-code. They did't create any negative target.

    let mut exponent = bytes_of(target);
    let mut coefficient;
    if (exponent <= 3) {
        let bits_shift: u8 = 8 * ( 3 - exponent);
        coefficient = get_last_32_bits(target) << bits_shift;
    } else {
        let bits_shift: u8 = 8 * (exponent - 3);
        let bn = target >> bits_shift;
        coefficient = get_last_32_bits(bn)
    };

    // handle case target is negative number.
    // 0x00800000 is set then it indicates a negative value
    // and target can be negative
    if (coefficient & 0x00800000 > 0) {
        // we push 00 before coefficet
        coefficient = coefficient >> 8;
        exponent = exponent + 1;
    };

    let compact = coefficient | ((exponent as u32) << 24);

    // TODO: Check case target is a negative number.
    // However, the target mustn't be a negative number

    compact
}

/// Converts bits to target. See documentation to the function above for more details.
public fun bits_to_target(bits: u32): u256 {
    let exponent = bits >> 3*8;

    // extract coefficient path or get last 24 bit of `bits`
    let mut target = (bits & 0x007fffff) as u256;

    if (exponent <= 3) {
        let bits_shift = (8 * (3 - exponent)) as u8;
        target = target >> bits_shift;
    } else {
        let bits_shift = (8 * (exponent - 3)) as u8;
        target = target << bits_shift;
    };
    target
}

// internal test
// TODO: Check best practice to improve test
#[test]
fun bytes_of_happy_cases() {
    assert_eq!(bytes_of(1), 1);
    assert_eq!(bytes_of(7), 1);
    assert_eq!(bytes_of(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), 32);
}

#[test]
/// get last 32 bits of number
fun get_last_32_bits_happy_cases() {
    assert_eq!(get_last_32_bits(0), 0);
    assert_eq!(
        get_last_32_bits(
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
        ),
        0xffffffff,
    );
    assert_eq!(get_last_32_bits(0x0123456789), 0x23456789);
}
