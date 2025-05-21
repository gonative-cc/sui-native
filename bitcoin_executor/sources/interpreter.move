module bitcoin_executor::interpreter;

use bitcoin_executor::reader::{Self, ScriptReader};
use bitcoin_executor::stack::{Self, Stack};
use std::unit_test::assert_eq;

// Opcodes
// push value
const OP_0: u8 = 0x00;
const OP_FALSE: u8 = OP_0;
const OP_PUSHBYTES_1: u8 = 0x01;
// TODO: do we need to add all the in-between constants?
const OP_PUSHBYTES_75: u8 = 0x4b;
const OP_PUSHDATA1: u8 = 0x4c;
const OP_PUSHDATA2: u8 = 0x4d;
const OP_PUSHDATA4: u8 = 0x4e;
const OP_1: u8 = 0x51;
const OP_TRUE: u8 = OP_1;
const OP_2: u8 = 0x52;
const OP_3: u8 = 0x53;
const OP_4: u8 = 0x54;
const OP_5: u8 = 0x55;
const OP_6: u8 = 0x56;
const OP_7: u8 = 0x57;
const OP_8: u8 = 0x58;
const OP_9: u8 = 0x59;
const OP_10: u8 = 0x5a;
const OP_11: u8 = 0x5b;
const OP_12: u8 = 0x5c;
const OP_13: u8 = 0x5d;
const OP_14: u8 = 0x5e;
const OP_15: u8 = 0x5f;
const OP_16: u8 = 0x60;
// stack ops
const OP_DUP: u8 = 0x76;

public struct Interpreter has copy, drop {
    stack: Stack,
    reader: ScriptReader,
}

public fun new(stack: Stack): Interpreter {
    Interpreter {
        stack: stack,
        reader: reader::new(vector[]), // empty reader
    }
}

/// Execute btc script
public fun run(script: vector<u8>): bool {
    let st = stack::create();
    let mut ip = new(st);
    let r = reader::new(script);
    ip.eval(r)
}

fun eval(ip: &mut Interpreter, r: ScriptReader): bool {
    ip.reader = r; // init new  reader
    while (!r.end_stream()) {
        let op = ip.reader.nextOpcode();

        if (op == OP_0) {
            ip.op_push_empty_vector();
            break
        } else if (op >= OP_PUSHBYTES_1 && op <= OP_PUSHBYTES_75) {
            ip.op_push_n_bytes(op);
        } else if (op >= OP_1 && op <= OP_16) {
            ip.op_push_small_int(op);
            break
        } else if (op == OP_DUP) {
            ip.op_dup();
            break
        };
    };

    ip.isSuccess()
}

/// check evaluate is valid
/// evaluation valid if the stack not empty
/// and top element is non zero value
public fun isSuccess(ip: &Interpreter): bool {
    if (ip.stack.is_empty()) {
        return false
    };
    let top = ip.stack.top();
    cast_to_bool(&top)
}

fun cast_to_bool(v: &vector<u8>): bool {
    let mut i = 0;
    while (i < v.length()) {
        if (v[i] != 0) {
            // Can be negative zero
            if (i == v.length()-1 && v[i] == 0x80) return false;
            return true;
        };
        i = i + 1;
    };
    false
}

fun op_push_empty_vector(ip: &mut Interpreter) {
    ip.stack.push(vector[]);
}

fun op_push_n_bytes(ip: &mut Interpreter, num_bytes_to_push: u8) {
    let data_to_push = ip.reader.read(num_bytes_to_push as u64);
    ip.stack.push(data_to_push);
}

fun op_push_small_int(ip: &mut Interpreter, opcode: u8) {
    // OP_1 (0x51) corresponds to 1  (0x51 - 0x50 = 0x01)
    // OP_16 (0x60) corresponds to 16 (0x60 - 0x50 = 0x10)
    let numeric_value: u8 = opcode - OP_1 + 1;
    ip.stack.push(vector[numeric_value]);
}

// OP_DUP eval
fun op_dup(ip: &mut Interpreter) {
    let value = ip.stack.top();
    ip.stack.push(value)
}

#[test]
fun test_op_0() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_push_empty_vector();

    assert!(ip.stack.size() == 1);
    let top_val = ip.stack.top();
    assert!(top_val.length() == 0);
    assert!(!ip.isSuccess());
}

#[test]
fun test_op_push_n_bytes() {
    let stack = stack::create();
    let mut ip = new(stack);
    let script = vector[0x01, 0x02, 0x03, 0x04, 0x05, 0x06];
    let reader = reader::new(script);
    ip.reader = reader;

    let num_bytes: u8 = 3;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x01, 0x02, 0x03]);
    assert_eq!(ip.isSuccess(), true);

    let num_bytes: u8 = 1;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 2);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x04]);
    assert_eq!(ip.isSuccess(), true);

    let num_bytes: u8 = 2;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 3);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x05, 0x06]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_1_push_small_int() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_push_small_int(OP_1);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x01]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_5_push_small_int() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_push_small_int(OP_5);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x05]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_16_push_small_int() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_push_small_int(OP_16);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top();
    assert_eq!(top_val, vector[0x10]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_dup() {
    let stack = stack::create_with_data(vector[vector[10]]);
    let mut ip = new(stack);
    ip.op_dup();
    assert_eq!(ip.stack.get_all_values(), vector[vector[10], vector[10]]);
    assert_eq!(ip.stack.size(), 2);
}
