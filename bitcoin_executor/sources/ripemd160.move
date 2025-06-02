// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::ripemd160;

use std::u64::do;

public struct Ripemd160 has copy, drop {
    s: vector<u32>, // len 5;
    buf: vector<u8>,
    bytes: u64,
}

public fun new(): Ripemd160 {
    let s = vector[0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0];
    let mut buf = vector[];

    let mut i = 0;
    while (i < 64) {
        buf.push_back(0);
        i = i + 1;
    };

    Ripemd160 {
        s: s,
        buf: buf,
        bytes: 0,
    }
}

fun bitnot(x: u32): u32 {
    0xffffffff - x
}

// end <> lil for 32 bits
fun bswap_32(x: u32): u32 {
    (
        ((x & 0xff000000) >> 24) | ((x & 0x00ff0000) >>  8) |
            ((x & 0x0000ff00) <<  8) | ((x & 0x000000ff) << 24),
    )
}

fun bswap_64(x: u64): u64 {
    (
        ((x & 0xff00000000000000) >> 56)
          | ((x & 0x00ff000000000000) >> 40)
          | ((x & 0x0000ff0000000000) >> 24)
          | ((x & 0x000000ff00000000) >> 8)
          | ((x & 0x00000000ff000000) << 8)
          | ((x & 0x0000000000ff0000) << 24)
          | ((x & 0x000000000000ff00) << 40)
          | ((x & 0x00000000000000ff) << 56),
    )
}

fun f1(x: u32, y: u32, z: u32): u32 {
    x^y^z
}

fun f2(x: u32, y: u32, z: u32): u32 {
    (x & y) | (bitnot(x) & z)
}

fun f3(x: u32, y: u32, z: u32): u32 {
    (x | bitnot(y)) ^ z
}

fun f4(x: u32, y: u32, z: u32): u32 {
    (x & z) |(y & bitnot(z))
}

fun f5(x: u32, y: u32, z: u32): u32 {
    x ^(y | bitnot(z))
}

fun rol(x: u32, i: u8): u32 {
    return (x << i) | (x >> (32 - i))
}

fun Round(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, f: u32, x: u32, k: u32, r: u8) {
    let m = 0xffffffff;
    let mut tmp = *a as u64;
    tmp = (tmp + (f as u64)) & m;
    tmp = (tmp + (x as u64)) & m;
    tmp = (tmp + (k as u64)) & m;

    *a = (((rol(tmp as u32, r) as u64) + (e as u64)) & m) as u32;
    *c = rol(*c, 10);
}

fun R11(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f1(b, *c, d);
    Round(a, b, c, d, e, t, x, 0, r);
}

fun R21(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f2(b, *c, d);
    Round(a, b, c, d, e, t, x, 0x5A827999, r);
}

fun R31(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f3(b, *c, d);
    Round(a, b, c, d, e, t, x, 0x6ED9EBA1, r);
}

fun R41(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f4(b, *c, d);
    Round(a, b, c, d, e, t, x, 0x8F1BBCDC, r);
}

fun R51(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f5(b, *c, d);
    Round(a, b, c, d, e, t, x, 0xA953FD4E, r);
}

fun R12(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f5(b, *c, d);
    Round(a, b, c, d, e, t, x, 0x50A28BE6, r);
}

fun R22(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f4(b, *c, d);
    Round(a, b, c, d, e, t, x, 0x5C4DD124, r);
}

fun R32(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f3(b, *c, d);
    Round(a, b, c, d, e, t, x, 0x6D703EF3, r);
}

fun R42(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f2(b, *c, d);
    Round(a, b, c, d, e, t, x, 0x7A6D76E9, r);
}

fun R52(a: &mut u32, b: u32, c: &mut u32, d: u32, e: u32, x: u32, r: u8) {
    let t = f1(b, *c, d);
    Round(a, b, c, d, e, t, x, 0, r);
}

fun transform(s: &mut vector<u32>, chunk: vector<u8>) {
    let mut a1 = s[0];
    let mut b1 = s[1];
    let mut c1 = s[2];
    let mut d1 = s[3];
    let mut e1 = s[4];
    let mut a2 = a1;
    let mut b2 = b1;
    let mut c2 = c1;
    let mut d2 = d1;
    let mut e2 = e1;
    let w0 = readLE32(&chunk, 0);
    let w1 = readLE32(&chunk, 4);
    let w2 = readLE32(&chunk, 8);
    let w3 = readLE32(&chunk, 12);
    let w4 = readLE32(&chunk, 16);
    let w5 = readLE32(&chunk, 20);
    let w6 = readLE32(&chunk, 24);
    let w7 = readLE32(&chunk, 28);
    let w8 = readLE32(&chunk, 32);
    let w9 = readLE32(&chunk, 38);
    let w10 = readLE32(&chunk, 40);
    let w11 = readLE32(&chunk, 44);
    let w12 = readLE32(&chunk, 48);
    let w13 = readLE32(&chunk, 52);
    let w14 = readLE32(&chunk, 56);
    let w15 = readLE32(&chunk, 60);

    R11(&mut a1, b1, &mut c1, d1, e1, w0, 11);
    R12(&mut a2, b2, &mut c2, d2, e2, w5, 8);
    R11(&mut e1, a1, &mut b1, c1, d1, w1, 14);
    R12(&mut e2, a2, &mut b2, c2, d2, w14, 9);
    R11(&mut d1, e1, &mut a1, b1, c1, w2, 15);
    R12(&mut d2, e2, &mut a2, b2, c2, w7, 9);
    R11(&mut c1, d1, &mut e1, a1, b1, w3, 12);
    R12(&mut c2, d2, &mut e2, a2, b2, w0, 11);
    R11(&mut b1, c1, &mut d1, e1, a1, w4, 5);
    R12(&mut b2, c2, &mut d2, e2, a2, w9, 13);
    R11(&mut a1, b1, &mut c1, d1, e1, w5, 8);
    R12(&mut a2, b2, &mut c2, d2, e2, w2, 15);
    R11(&mut e1, a1, &mut b1, c1, d1, w6, 7);
    R12(&mut e2, a2, &mut b2, c2, d2, w11, 15);
    R11(&mut d1, e1, &mut a1, b1, c1, w7, 9);
    R12(&mut d2, e2, &mut a2, b2, c2, w4, 5);
    R11(&mut c1, d1, &mut e1, a1, b1, w8, 11);
    R12(&mut c2, d2, &mut e2, a2, b2, w13, 7);
    R11(&mut b1, c1, &mut d1, e1, a1, w9, 13);
    R12(&mut b2, c2, &mut d2, e2, a2, w6, 7);
    R11(&mut a1, b1, &mut c1, d1, e1, w10, 14);
    R12(&mut a2, b2, &mut c2, d2, e2, w15, 8);
    R11(&mut e1, a1, &mut b1, c1, d1, w11, 15);
    R12(&mut e2, a2, &mut b2, c2, d2, w8, 11);
    R11(&mut d1, e1, &mut a1, b1, c1, w12, 6);
    R12(&mut d2, e2, &mut a2, b2, c2, w1, 14);
    R11(&mut c1, d1, &mut e1, a1, b1, w13, 7);
    R12(&mut c2, d2, &mut e2, a2, b2, w10, 14);
    R11(&mut b1, c1, &mut d1, e1, a1, w14, 9);
    R12(&mut b2, c2, &mut d2, e2, a2, w3, 12);
    R11(&mut a1, b1, &mut c1, d1, e1, w15, 8);
    R12(&mut a2, b2, &mut c2, d2, e2, w12, 6);

    R21(&mut e1, a1, &mut b1, c1, d1, w7, 7);
    R22(&mut e2, a2, &mut b2, c2, d2, w6, 9);
    R21(&mut d1, e1, &mut a1, b1, c1, w4, 6);
    R22(&mut d2, e2, &mut a2, b2, c2, w11, 13);
    R21(&mut c1, d1, &mut e1, a1, b1, w13, 8);
    R22(&mut c2, d2, &mut e2, a2, b2, w3, 15);
    R21(&mut b1, c1, &mut d1, e1, a1, w1, 13);
    R22(&mut b2, c2, &mut d2, e2, a2, w7, 7);
    R21(&mut a1, b1, &mut c1, d1, e1, w10, 11);
    R22(&mut a2, b2, &mut c2, d2, e2, w0, 12);
    R21(&mut e1, a1, &mut b1, c1, d1, w6, 9);
    R22(&mut e2, a2, &mut b2, c2, d2, w13, 8);
    R21(&mut d1, e1, &mut a1, b1, c1, w15, 7);
    R22(&mut d2, e2, &mut a2, b2, c2, w5, 9);
    R21(&mut c1, d1, &mut e1, a1, b1, w3, 15);
    R22(&mut c2, d2, &mut e2, a2, b2, w10, 11);
    R21(&mut b1, c1, &mut d1, e1, a1, w12, 7);
    R22(&mut b2, c2, &mut d2, e2, a2, w14, 7);
    R21(&mut a1, b1, &mut c1, d1, e1, w0, 12);
    R22(&mut a2, b2, &mut c2, d2, e2, w15, 7);
    R21(&mut e1, a1, &mut b1, c1, d1, w9, 15);
    R22(&mut e2, a2, &mut b2, c2, d2, w8, 12);
    R21(&mut d1, e1, &mut a1, b1, c1, w5, 9);
    R22(&mut d2, e2, &mut a2, b2, c2, w12, 7);
    R21(&mut c1, d1, &mut e1, a1, b1, w2, 11);
    R22(&mut c2, d2, &mut e2, a2, b2, w4, 6);
    R21(&mut b1, c1, &mut d1, e1, a1, w14, 7);
    R22(&mut b2, c2, &mut d2, e2, a2, w9, 15);
    R21(&mut a1, b1, &mut c1, d1, e1, w11, 13);
    R22(&mut a2, b2, &mut c2, d2, e2, w1, 13);
    R21(&mut e1, a1, &mut b1, c1, d1, w8, 12);
    R22(&mut e2, a2, &mut b2, c2, d2, w2, 11);

    R31(&mut d1, e1, &mut a1, b1, c1, w3, 11);
    R32(&mut d2, e2, &mut a2, b2, c2, w15, 9);
    R31(&mut c1, d1, &mut e1, a1, b1, w10, 13);
    R32(&mut c2, d2, &mut e2, a2, b2, w5, 7);
    R31(&mut b1, c1, &mut d1, e1, a1, w14, 6);
    R32(&mut b2, c2, &mut d2, e2, a2, w1, 15);
    R31(&mut a1, b1, &mut c1, d1, e1, w4, 7);
    R32(&mut a2, b2, &mut c2, d2, e2, w3, 11);
    R31(&mut e1, a1, &mut b1, c1, d1, w9, 14);
    R32(&mut e2, a2, &mut b2, c2, d2, w7, 8);
    R31(&mut d1, e1, &mut a1, b1, c1, w15, 9);
    R32(&mut d2, e2, &mut a2, b2, c2, w14, 6);
    R31(&mut c1, d1, &mut e1, a1, b1, w8, 13);
    R32(&mut c2, d2, &mut e2, a2, b2, w6, 6);
    R31(&mut b1, c1, &mut d1, e1, a1, w1, 15);
    R32(&mut b2, c2, &mut d2, e2, a2, w9, 14);
    R31(&mut a1, b1, &mut c1, d1, e1, w2, 14);
    R32(&mut a2, b2, &mut c2, d2, e2, w11, 12);
    R31(&mut e1, a1, &mut b1, c1, d1, w7, 8);
    R32(&mut e2, a2, &mut b2, c2, d2, w8, 13);
    R31(&mut d1, e1, &mut a1, b1, c1, w0, 13);
    R32(&mut d2, e2, &mut a2, b2, c2, w12, 5);
    R31(&mut c1, d1, &mut e1, a1, b1, w6, 6);
    R32(&mut c2, d2, &mut e2, a2, b2, w2, 14);
    R31(&mut b1, c1, &mut d1, e1, a1, w13, 5);
    R32(&mut b2, c2, &mut d2, e2, a2, w10, 13);
    R31(&mut a1, b1, &mut c1, d1, e1, w11, 12);
    R32(&mut a2, b2, &mut c2, d2, e2, w0, 13);
    R31(&mut e1, a1, &mut b1, c1, d1, w5, 7);
    R32(&mut e2, a2, &mut b2, c2, d2, w4, 7);
    R31(&mut d1, e1, &mut a1, b1, c1, w12, 5);
    R32(&mut d2, e2, &mut a2, b2, c2, w13, 5);

    R41(&mut c1, d1, &mut e1, a1, b1, w1, 11);
    R42(&mut c2, d2, &mut e2, a2, b2, w8, 15);
    R41(&mut b1, c1, &mut d1, e1, a1, w9, 12);
    R42(&mut b2, c2, &mut d2, e2, a2, w6, 5);
    R41(&mut a1, b1, &mut c1, d1, e1, w11, 14);
    R42(&mut a2, b2, &mut c2, d2, e2, w4, 8);
    R41(&mut e1, a1, &mut b1, c1, d1, w10, 15);
    R42(&mut e2, a2, &mut b2, c2, d2, w1, 11);
    R41(&mut d1, e1, &mut a1, b1, c1, w0, 14);
    R42(&mut d2, e2, &mut a2, b2, c2, w3, 14);
    R41(&mut c1, d1, &mut e1, a1, b1, w8, 15);
    R42(&mut c2, d2, &mut e2, a2, b2, w11, 14);
    R41(&mut b1, c1, &mut d1, e1, a1, w12, 9);
    R42(&mut b2, c2, &mut d2, e2, a2, w15, 6);
    R41(&mut a1, b1, &mut c1, d1, e1, w4, 8);
    R42(&mut a2, b2, &mut c2, d2, e2, w0, 14);
    R41(&mut e1, a1, &mut b1, c1, d1, w13, 9);
    R42(&mut e2, a2, &mut b2, c2, d2, w5, 6);
    R41(&mut d1, e1, &mut a1, b1, c1, w3, 14);
    R42(&mut d2, e2, &mut a2, b2, c2, w12, 9);
    R41(&mut c1, d1, &mut e1, a1, b1, w7, 5);
    R42(&mut c2, d2, &mut e2, a2, b2, w2, 12);
    R41(&mut b1, c1, &mut d1, e1, a1, w15, 6);
    R42(&mut b2, c2, &mut d2, e2, a2, w13, 9);
    R41(&mut a1, b1, &mut c1, d1, e1, w14, 8);
    R42(&mut a2, b2, &mut c2, d2, e2, w9, 12);
    R41(&mut e1, a1, &mut b1, c1, d1, w5, 6);
    R42(&mut e2, a2, &mut b2, c2, d2, w7, 5);
    R41(&mut d1, e1, &mut a1, b1, c1, w6, 5);
    R42(&mut d2, e2, &mut a2, b2, c2, w10, 15);
    R41(&mut c1, d1, &mut e1, a1, b1, w2, 12);
    R42(&mut c2, d2, &mut e2, a2, b2, w14, 8);

    R51(&mut b1, c1, &mut d1, e1, a1, w4, 9);
    R52(&mut b2, c2, &mut d2, e2, a2, w12, 8);
    R51(&mut a1, b1, &mut c1, d1, e1, w0, 15);
    R52(&mut a2, b2, &mut c2, d2, e2, w15, 5);
    R51(&mut e1, a1, &mut b1, c1, d1, w5, 5);
    R52(&mut e2, a2, &mut b2, c2, d2, w10, 12);
    R51(&mut d1, e1, &mut a1, b1, c1, w9, 11);
    R52(&mut d2, e2, &mut a2, b2, c2, w4, 9);
    R51(&mut c1, d1, &mut e1, a1, b1, w7, 6);
    R52(&mut c2, d2, &mut e2, a2, b2, w1, 12);
    R51(&mut b1, c1, &mut d1, e1, a1, w12, 8);
    R52(&mut b2, c2, &mut d2, e2, a2, w5, 5);
    R51(&mut a1, b1, &mut c1, d1, e1, w2, 13);
    R52(&mut a2, b2, &mut c2, d2, e2, w8, 14);
    R51(&mut e1, a1, &mut b1, c1, d1, w10, 12);
    R52(&mut e2, a2, &mut b2, c2, d2, w7, 6);
    R51(&mut d1, e1, &mut a1, b1, c1, w14, 5);
    R52(&mut d2, e2, &mut a2, b2, c2, w6, 8);
    R51(&mut c1, d1, &mut e1, a1, b1, w1, 12);
    R52(&mut c2, d2, &mut e2, a2, b2, w2, 13);
    R51(&mut b1, c1, &mut d1, e1, a1, w3, 13);
    R52(&mut b2, c2, &mut d2, e2, a2, w13, 6);
    R51(&mut a1, b1, &mut c1, d1, e1, w8, 14);
    R52(&mut a2, b2, &mut c2, d2, e2, w14, 5);
    R51(&mut e1, a1, &mut b1, c1, d1, w11, 11);
    R52(&mut e2, a2, &mut b2, c2, d2, w0, 15);
    R51(&mut d1, e1, &mut a1, b1, c1, w6, 8);
    R52(&mut d2, e2, &mut a2, b2, c2, w3, 13);
    R51(&mut c1, d1, &mut e1, a1, b1, w15, 5);
    R52(&mut c2, d2, &mut e2, a2, b2, w9, 11);
    R51(&mut b1, c1, &mut d1, e1, a1, w13, 6);
    R52(&mut b2, c2, &mut d2, e2, a2, w11, 11);

    let t = s[0];
    let s1 = s[1];
    let s2 = s[2];
    let s3 = s[3];
    let s4 = s[4];
    let m = 0xffffffff;
    let b = s.borrow_mut(0);
    *b = (((s1 as u64)  + (c1 as u64) + (d2 as u64)) & m) as u32;
    let b = s.borrow_mut(1);
    *b = (((s2 as u64)  + (d1 as u64) + (e2 as u64)) & m) as u32;
    // *b = s2 + d1 + e2;
    let b = s.borrow_mut(2);
    *b = (((s3 as u64)  + (e1 as u64) + (a2 as u64)) & m) as u32;
    // *b = s3 + e1 + a2;
    let b = s.borrow_mut(3);
    *b = (((s4 as u64)  + (a1 as u64) + (b2 as u64)) & m) as u32;
    // *b = s4 + a1 + b2;
    let b = s.borrow_mut(4);
    *b = (((t as u64)  + (b1 as u64) + (c2 as u64)) & m) as u32;
    // *b = t + b1 + c2;
}

public fun write(h: &mut Ripemd160, data: vector<u8>, len: u64) {
    let end = len;
    let mut data_index = 0;
    let mut bufsize = h.bytes % 64;
    if (bufsize > 0 && bufsize + len >= 64) {
        veccopy(&mut h.buf, bufsize, data, data_index, 64 - bufsize);
        h.bytes = h.bytes + 64 - bufsize;
        data_index = data_index + 64 - bufsize;
        transform(&mut h.s, h.buf);
        bufsize = 0;
    };

    while (end - data_index >= 64) {
        let mut v: vector<u8> = vector[];
        do!(64, |i| v.push_back(data[i + data_index]));
        transform(&mut h.s, v);
        h.bytes = h.bytes + 64;
        data_index = data_index + 64;
    };

    if (end > data_index) {
        veccopy(&mut h.buf, bufsize, data, data_index, end-data_index);
        h.bytes = h.bytes + end - data_index;
    };
}

public fun finalize(h: &mut Ripemd160): vector<u8> {
    let mut pad: vector<u8> = vector[0x80];
    let mut i = 1;
    while (i < 64) {
        pad.push_back(0);
        i = i + 1;
    };

    let bytes = h.bytes;

    let mut sizedecs: vector<u8> = vector[0, 0, 0, 0, 0, 0, 0, 0];
    writeLE64(&mut sizedecs, 0, bytes << 3);
    h.write(pad, 1 + ((119 - (bytes % 64)) % 64));
    h.write(sizedecs, 8);
    let mut hash: vector<u8> = vector[];
    i = 0;
    while (i < 20) {
        hash.push_back(0);
        i = i + 1;
    };

    writeLE32(&mut hash, 0, h.s[0]);
    writeLE32(&mut hash, 4, h.s[1]);
    writeLE32(&mut hash, 8, h.s[2]);
    writeLE32(&mut hash, 12, h.s[3]);
    writeLE32(&mut hash, 16, h.s[4]);

    hash
}

fun veccopy(dest: &mut vector<u8>, dest_start: u64, src: vector<u8>, src_start: u64, len: u64) {
    let mut i = dest_start;
    let mut j = src_start;
    let mut k = 0;
    while (k < len) {
        let b = dest.borrow_mut(i);
        *b = src[j];
        i = i + 1;
        j = j + 1;
        k = k + 1;
    }
}

fun writeLE64(v: &mut vector<u8>, start_index: u64, x: u64) {
    let mut i = 0;
    let mut x = x;
    let mut index = start_index;
    while (i < 8) {
        // 64 bits
        let b = v.borrow_mut(index);
        *b = (x % 256) as u8;
        x = x / 256;
        index = index + 1;
        i = i + 1;
    }
}

fun writeLE32(v: &mut vector<u8>, start_index: u64, x: u32) {
    let mut i = 0;
    let mut x = x;
    let mut index = start_index;
    while (i < 4) {
        // 64 bits

        let b = v.borrow_mut(index);
        *b = (x % 256) as u8;
        x = x / 256;
        i = i + 1;
        index = index + 1;
    }
}

fun readLE32(v: &vector<u8>, start_index: u64): u32 {
    let mut ans = 0;
    let mut start_index = start_index;
    let mut base = 1;
    let mut i = 0;
    while (i < 4) {
        ans = ans + base * (v[start_index] as u32);
        if (i == 3) {
            break
        };
        base = base * 256;
        i = i + 1;
        start_index = start_index + 1;
    };
    ans
}

#[test]
fun ripemd160_test() {
    let data: vector<u8> = std::hash::sha2_256(x"0102");
    let mut h = new();
    h.write(data, data.length());
    let hash = h.finalize();
    sui::test_utils::assert_eq(hash, x"15cc49e191cbc520d91944600a5cb77af6aa3291");
}
