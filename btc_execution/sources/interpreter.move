module btc_execution::interpreter;
use btc_execution::opcode::isOpSuccess;
use btc_execution::stack::{Stack, Self};

// TODO: Follow error in btc implemetation
#[error]
const EBadReadData: vector<u8> = b"Invalid read script";
#[error]
const EBadOpcode: vector<u8> = b"Bad opcode";


public struct ScriptReader has copy, drop {
    script: vector<u8>,
    current_index: u64
}

public struct Interperter has copy, drop {
    stack: Stack
}

/// Execute btc script

public fun run(script: &vector<u8>): bool {
    let mut interperter = Interperter {
        stack : stack::create()
    };

    interperter.eval(script)
}

fun eval(interperter: &mut Interperter, script: &vector<u8>): bool {
    // eval script and check result
    interperter.isExecuteSuccess()
}





/// check evaluate is valid
/// evaluation valid if the stack not empty
/// and top element is non zero value
public fun isExecuteSuccess(interperter: &Interperter): bool {
    if (interperter.stack.is_empty()) {
        return false
    };
    let top = interperter.stack.top();
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
