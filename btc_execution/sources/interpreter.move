module btc_execution::interpreter;
use btc_execution::stack::{Stack, Self};
use btc_execution::reader::{ScriptReader, Self};


//=============== Opcodes =============================================

/// Duplicate the top item on the stack.
const OP_DUP: u8 = 0x76; // 118
/// Compare the top two items on the stack and push 1 if they are equal, 0 otherwise.
const OP_EQUAL: u8 = 0x87; // 135
/// Compare the top two items on the stack and halts the script if they are not equal.
const OP_EQUALVERIFY: u8 = 0x88; // 136

// errors
#[error]
const EEqualVerify: vector<u8> = b"SCRIPT_ERR_EQUALVERIFY";

public struct Interpreter has copy, drop {
    stack: Stack,
    reader: ScriptReader
}


public fun new(stack: Stack): Interpreter {
    Interpreter {
        stack : stack,
        reader: reader::new(vector[]) // empty reader
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
    while(!r.end_stream()) {
        let op = ip.reader.nextOpcode();
        if (op == OP_DUP) {
            ip.op_dup();
        };
        if (op == OP_EQUAL) {
            ip.op_equal();
        };
        if (op == OP_EQUALVERIFY) {
            ip.op_equal_verify();
        }
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
             if (i == v.length()-1 && v[i] == 0x80)
                return false;
            return true;
        };
        i = i + 1;
    };
    false
}


fun op_equal(ip: &mut Interpreter) {
    let first_value = ip.stack.pop();
    let second_value = ip.stack.pop();
    let ans = if (first_value == second_value) {
        vector[1]
    } else {
        vector[0]
    };
    ip.stack.push(ans);
}

fun op_equal_verify(ip:&mut Interpreter) {
    ip.op_equal();
    assert!(ip.stack.pop() == vector[1], EEqualVerify);
}

// OP_DUP eval
fun op_dup(ip: &mut Interpreter) {
    let value = ip.stack.top();
    ip.stack.push(value)
}

#[test]
fun test_op_equal() {
    let stack = stack::create_with_data(vector[vector[10], vector[10]]);
    let mut ip = new(stack);
    ip.op_equal();
    assert!(ip.stack.top() == vector[1]);

    let stack = stack::create_with_data(vector[vector[20], vector[10]]);
    let mut ip = new(stack);
    ip.op_equal();
    assert!(ip.stack.top() == vector[0]);
}

#[test]
fun test_op_equal_verify() {
    let stack = stack::create_with_data(vector[vector[10], vector[10]]);
    let mut ip = new(stack);
    ip.op_equal_verify();
}

#[test, expected_failure(abort_code = EEqualVerify)]
fun test_op_equal_verify_fail() {
    let stack = stack::create_with_data(vector[vector[10], vector[12]]);
    let mut ip = new(stack);
    ip.op_equal_verify();
}

#[test, expected_failure(abort_code = stack::EPopStackEmpty)]
fun test_op_equal_fail() {
    let stack = stack::create_with_data(vector[vector[10]]);
    let mut ip = new(stack);
    ip.op_equal();
}

#[test]
fun test_op_dup() {
    let stack = stack::create_with_data(vector[vector[10]]);
    let mut ip = new(stack);
    ip.op_dup();
    assert!(ip.stack.get_all_value() == vector[vector[10], vector[10]]);
    assert!(ip.stack.size() == 2);
}

#[test, expected_failure(abort_code = stack::EPopStackEmpty)]
fun test_op_dup_fail() {
    let stack = stack::create();
    let mut ip = new(stack);
    ip.op_dup();
}
