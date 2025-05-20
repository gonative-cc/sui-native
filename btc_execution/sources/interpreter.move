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

public struct Interperter has copy, drop {
    stack: Stack
}

public fun reader(script: vector<u8>): ScriptReader {
    ScriptReader {
        script: script,
        current_index: 0,
    }
}

public fun create_interperter(): Interperter {
    Interperter {
        stack : stack::create()
    }
}

/// Execute btc script
public fun run(script: vector<u8>): bool {
    let mut interperter = create_interperter();
    let mut r = reader(script);
    interperter.eval(&mut r)
}

fun eval(ip: &mut Interperter, r: &mut ScriptReader): bool {

    while(!r.end_stream()) {
        let op = r.nextOpcode();

        if (op == OP_DUP) {
            ip.op_dup()
        }
    };

    ip.isExecuteSuccess()
}


/// check evaluate is valid
/// evaluation valid if the stack not empty
/// and top element is non zero value
public fun isExecuteSuccess(ip: &Interperter): bool {
    if (ip.stack.is_empty()) {
        return false
    };
    let top = ip.stack.top();
    return cast_to_bool(&top)
}

public fun nextOpcode(r: &mut ScriptReader): u8 {
    let opcode = r.read(1)[0];
    assert!(isOpSuccess(opcode), EBadOpcode);
    opcode
}


fun read(r: &mut ScriptReader, cap: u64): vector<u8> {
    assert!(r.readable(cap), EBadReadData);

    let mut i = r.current_index;
    let mut buf =vector[];
    while (i < cap) {
        buf.push_back(r.script[i]);
        i = i + 1;
    };

    r.current_index = r.current_index + cap;
    buf
}

fun readable(r: &ScriptReader, i: u64):  bool {
    r.current_index + i < r.script.length()
}

fun end_stream(r: &ScriptReader): bool {
    r.current_index < r.script.length()
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
    return false
}


// OP_DUP eval
fun op_dup(ip: &mut Interperter) {
    let value = ip.stack.top();
    ip.stack.push(value)
}
