module btc_execution::interpreter;
use btc_execution::opcode::isOpSuccess;
use btc_execution::stack::Stack;

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
public fun run(interperter: &mut Interperter, script: vector<u8>) : bool {
    return true
}


public fun isExecuteSuccess(interperter: &Interperter): bool {
    interperter.stack.size() == 1 &&
        // TODO: this should not zero value
        interperter.stack.top() != vector[0]
}

public fun nextOpcode(r: &mut ScriptReader): u8 {
    let opcode = r.read(1)[0];
    assert!(isOpSuccess(opcode), EBadOpcode);
    opcode
}


fun read(r: &mut ScriptReader, cap: u64): vector<u8> {
    let mut i = r.current_index;
    assert!(r.readable(cap), EBadReadData);
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
