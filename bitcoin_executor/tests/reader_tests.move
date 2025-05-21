#[test_only]
module bitcoin_executor::reader_tests;

use bitcoin_executor::reader::{ScriptReader, Self};
use sui::test_utils::assert_eq;

#[test]
fun readable() {
    let r = reader::new(vector[1, 2, 3]);

    assert!(r.readable(1));
    assert!(r.readable(2));
    assert!(r.readable(3));
    assert!(!r.readable(4));
}

#[test]
fun end_stream() {
    let mut r = reader::new(vector[1, 2, 3]);
    assert!(!r.end_stream());
    r.read(3);
    assert!(r.end_stream());
}


#[test]
fun read_byte() {
    let mut r = reader::new(vector[1]);
    assert_eq(r.read_byte(), 1);
}


#[test]
fun read() {
    let mut r = reader::new(vector[1, 2, 3]);
    let b = r.read(2);
    assert_eq(b, vector[1, 2]);
    let b = r.read(1);
    assert_eq(b, vector[3]);
}

#[test]
fun next_opcode() {
    let mut r = reader::new(vector[80, 1, 2]);
    assert_eq(r.next_opcode(), 80);
    assert_eq(r.next_opcode(), 1);
    assert_eq(r.next_opcode(), 2);
}

#[test, expected_failure(abort_code = reader::EBadReadData)]
fun read_fail() {
    let mut r = reader::new(vector[1, 2, 3]);
    r.read(10);
    abort
}

#[test, expected_failure(abort_code = reader::EBadReadData)]
fun read_fail_empty_script() {
    let mut r = reader::new(vector[]);
    r.read(10);
    abort
}

#[test, expected_failure(abort_code = reader::EBadReadData)]
fun read_endstream_script() {
    let mut r = reader::new(vector[1, 2, 3]);
    let b = r.read(3);
    // check data after read
    assert_eq(b, vector[1, 2, 3]);
    // check status of reader
    assert!(r.end_stream());
    assert!(!r.readable(1));
    // read more to ensure this must be return error
    r.read(10);
    abort
}
