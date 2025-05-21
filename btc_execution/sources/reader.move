module btc_execution::reader;

use btc_execution::opcode::isValid;

#[error]
const EBadOpcode: vector<u8> = b"Bad opcode";


// TODO: Follow error in btc implemetation
#[error]
const EBadReadData: vector<u8> = b"Invalid read script";


public struct ScriptReader has copy, drop {
    script: vector<u8>,
    current_index: u64
}

public fun new(script: vector<u8>): ScriptReader {
    ScriptReader {
        script: script,
        current_index: 0,
    }
}


/// read `len` amount of bytes from the ScriptReader
public fun read(r: &mut ScriptReader, len: u64): vector<u8> {
    assert!(r.readable(len), EBadReadData);

    let mut i = r.current_index;
    let mut j = 0;
    let mut buf = vector[];
    while (j < len) {
        buf.push_back(r.script[i]);
        j = j + 1;
        i = i + 1;
    };

    r.current_index = i;
    buf
}

public fun read_byte(r: &mut ScriptReader, cap: u64): u8 {
    let b = r.script[r.next_index];
    r.next_index += 1;
    return b;
}
public fun readable(r: &ScriptReader, i: u64):  bool {
    r.current_index + i <= r.script.length()
}

public fun end_stream(r: &ScriptReader): bool {
    r.current_index >= r.script.length()
}



public fun nextOpcode(r: &mut ScriptReader): u8 {
    let opcode = r.read_byte();
    assert!(isValid(opcode), EBadOpcode);
    opcode
}
