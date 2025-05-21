module btc_execution::reader;

use btc_execution::opcode::isValid;

#[error]
const EBadOpcode: vector<u8> = b"Bad opcode";


// TODO: Follow error in btc implemetation
#[error]
const EBadReadData: vector<u8> = b"Invalid read script";


public struct ScriptReader has copy, drop {
    script: vector<u8>,
    next_index: u64
}

/// create a new reader
public fun new(script: vector<u8>): ScriptReader {
    ScriptReader {
        script: script,
        next_index: 0,
    }
}

/// check can read next len bytes
public fun readable(r: &ScriptReader, len: u64):  bool {
    r.next_index + len <= r.script.length()
}

/// check stream is end
public fun end_stream(r: &ScriptReader): bool {
    r.next_index >= r.script.length()
}

/// read `len` amount of bytes from the ScriptReader
public fun read(r: &mut ScriptReader, len: u64): vector<u8> {
    assert!(r.readable(len), EBadReadData);

    let mut i = r.next_index;
    let mut j = 0;
    let mut buf = vector[];
    while (j < len) {
        buf.push_back(r.script[i]);
        j = j + 1;
        i = i + 1;
    };

    r.next_index = i;
    buf

}

/// read the next byte of stream
public fun read_byte(r: &mut ScriptReader): u8 {
    let b = r.script[r.next_index];
    r.next_index = r.next_index + 1;
    b
}

/// Return the next opcode
public fun nextOpcode(r: &mut ScriptReader): u8 {
    let opcode = r.read_byte();
    assert!(isValid(opcode), EBadOpcode);
    opcode
}
