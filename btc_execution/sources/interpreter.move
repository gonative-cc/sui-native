module btc_execution::interpreter;
use btc_execution::opcode::isOpSuccess;
use btc_execution::stack::{Stack, Self};


// TODO: Follow error in btc implemetation
#[error]
const EBadReadData: vector<u8> = b"Invalid read script";
#[error]
const EBadOpcode: vector<u8> = b"Bad opcode";


// Opcodes

const OP_DUP: u8 = 76;


public struct ScriptReader has copy, drop {
    script: vector<u8>,
    current_index: u64
}

public struct Interpreter has copy, drop {
    stack: Stack
}

public fun reader(script: vector<u8>): ScriptReader {
    ScriptReader {
        script: script,
        current_index: 0,
    }
}

public fun create_interperter(stack: Stack): Interpreter {
    Interpreter {
        stack : stack
    }
}

/// Execute btc script
public fun run(script: vector<u8>): bool {
    let st = stack::create();
    let mut ip = create_interperter(st);
    let mut r = reader(script);
    ip.eval(&mut r)
}

fun eval(ip: &mut Interpreter, r: &mut ScriptReader): bool {

    while(!r.end_stream()) {
        let op = r.nextOpcode();

        if (op == OP_DUP) {
            ip.op_dup();
            break
        };
    };

    ip.isExecuteSuccess()
}


/// check evaluate is valid
/// evaluation valid if the stack not empty
/// and top element is non zero value
public fun isExecuteSuccess(ip: &Interpreter): bool {
    if (ip.stack.is_empty()) {
        return false
    };
    let top = ip.stack.top();
    cast_to_bool(&top)
}

public fun nextOpcode(r: &mut ScriptReader): u8 {
    let opcode = r.read(1)[0];
    assert!(isOpSuccess(opcode), EBadOpcode);
    opcode
}


fun read(r: &mut ScriptReader, cap: u64): vector<u8> {
    assert!(r.readable(cap), EBadReadData);

    let mut i = r.current_index;
    let mut j = 0;
    let mut buf = vector[];
    while (j < cap) {
        buf.push_back(r.script[i]);
        j = j + 1;
        i = i + 1;
    };

    r.current_index = j;
    buf
}

fun readable(r: &ScriptReader, i: u64):  bool {
    r.current_index + i <= r.script.length()
}

fun end_stream(r: &ScriptReader): bool {
    r.current_index >= r.script.length()
}

fun cast_to_bool(v: &vector<u8>): bool {
    let mut i = 0;
    while (i < v.length()) {
        if (v[i] != 0) {
            // Can be negetive zero
             if (i == v.length()-1 && v[i] == 0x80)
                return false;
            return true;
        };
        i = i + 1;
    };
    false
}


// OP_DUP eval
fun op_dup(ip: &mut Interpreter) {
    let value = ip.stack.top();
    ip.stack.push(value)
}


#[test]
fun test_op_dup() {
    let stack = stack::create_with_data(vector[vector[10]]);
    let mut ip = create_interperter(stack);
    ip.op_dup();
    assert!(ip.stack.get_all_value() == vector[vector[10], vector[10]]);
    assert!(ip.stack.size() == 2);
}
