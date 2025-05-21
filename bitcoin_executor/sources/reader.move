module bitcoin_executor::reader;


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
    assert!(isOpSuccess(opcode), EBadOpcode);
    opcode
}

/// isSuccess tracks the set of op codes that are to be interpreted as op
/// codes that cause execution to automatically succeed.
public fun isOpSuccess(opcode: u8): bool {
    // https://github.com/bitcoin/bitcoin/blob/v29.0/src/script/script.cpp#L358
    opcode == 80 || opcode == 98 || (opcode >= 126 && opcode <= 129) ||
        (opcode >= 131 && opcode <= 134) || (opcode >= 137 && opcode <= 138) ||
        (opcode >= 141 && opcode <= 142) || (opcode >= 149 && opcode <= 153) ||
        (opcode >= 187 && opcode <= 254)
}
