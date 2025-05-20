module btc_execution::interpreter;
use btc_execution::stack::{Stack, Self};
use btc_execution::reader::{ScriptReader, Self};


// Opcodes
const OP_DUP: u8 = 76;

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


// OP_DUP eval
fun op_dup(ip: &mut Interpreter) {
    let value = ip.stack.top();
    ip.stack.push(value)
}


#[test]
fun test_op_dup() {
    let stack = stack::create_with_data(vector[vector[10]]);
    let mut ip = new(stack);
    ip.op_dup();
    assert!(ip.stack.get_all_values() == vector[vector[10], vector[10]]);
    assert!(ip.stack.size() == 2);
}
