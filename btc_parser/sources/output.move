module btc_parser::output;

use btc_parser::utils::u64_to_le_bytes;
use btc_parser::utils::vector_slice;

// === BTC script opcodes ===
/// An empty array of bytes is pushed onto the stack. (This is not a no-op: an item is added to the stack.)
const OP_0: u8 = 0x00;
/// Duplicates the top stack item
const OP_DUP: u8 = 0x76;
/// Pop the top stack item and push its RIPEMD(SHA256(top item)) hash
const OP_HASH160: u8 = 0xa9;
/// Push the next 20 bytes as an array onto the stack
const OP_DATA_20: u8 = 0x14;
/// Returns success if the inputs are exactly equal, failure otherwise
const OP_EQUALVERIFY: u8 = 0x88;
/// https://en.bitcoin.it/wiki/OP_CHECKSIG pushing 1/0 for success/failure
const OP_CHECKSIG: u8 = 0xac;
/// nulldata script
const OP_RETURN: u8 = 0x6a;
/// Read the next 4 bytes as N. Push the next N bytes as an array onto the stack.
const OP_PUSHDATA4: u8 = 0x4e;
/// Read the next 2 bytes as N. Push the next N bytes as an array onto the stack.
const OP_PUSHDATA2: u8 = 0x4d;
/// Read the next byte as N. Push the next N bytes as an array onto the stack.
const OP_PUSHDATA1: u8 = 0x4c;
/// Push the next 75 bytes onto the stack.
const OP_DATA_75: u8 = 0x4b;


/// Output in btc transaction
public struct Output has copy, drop, store {
    amount: u64,
    amount_bytes: vector<u8>,
    script_pubkey: vector<u8>,
}

public fun new(amount: u64, script_pubkey: vector<u8>): Output {
    Output {
        amount,
        amount_bytes: u64_to_le_bytes(amount),
        script_pubkey,
    }
}

public fun amount_bytes(output: &Output): vector<u8> {
    output.amount_bytes
}
public fun amount(output: &Output): u64 {
    output.amount
}

public fun script_pubkey(output: &Output): vector<u8> {
    output.script_pubkey
}

public fun is_P2PHK(output: &Output): bool {
    let script = output.script_pubkey();

    script.length() == 25 &&
		script[0] == OP_DUP &&
		script[1] == OP_HASH160 &&
		script[2] == OP_DATA_20 &&
		script[23] == OP_EQUALVERIFY &&
		script[24] == OP_CHECKSIG
}

public fun is_op_return(output: &Output): bool {
    let script = output.script_pubkey;
    script.length() > 0 && script[0] == OP_RETURN
}

public fun is_P2WPHK(output: &Output): bool {
    let script = output.script_pubkey;
    script.length() == 22 &&
        script[0] == OP_0 &&
        script[1] == OP_DATA_20
}

// TODO: add support script addresses.
// TODO: check and verify the address to make sure we support it. Return error otherwise
/// extract pkh from the output in P2PHK or P2WPKH
/// return empty if the cannot extract public key hash
public fun extract_public_key_hash(output: &Output): vector<u8> {
    let script = output.script_pubkey;
    if (output.is_P2PHK()) {
        return vector_slice(&script, 3, 23)
    } else if (output.is_P2WPHK()) {
        return vector_slice(&script, 2, 22)
    };
    vector[]
}

/// Extracts the data payload from an OP_RETURN output in a transaction.
/// script = OP_RETURN <data>.
/// If transaction mined to BTC, then this must pass basic conditions
/// include the conditions for OP_RETURN script.
/// This why we only return the message without check size message.
public fun op_return(output: &Output): vector<u8> {
    let script = output.script_pubkey;

    if (script.length() == 1) {
        return vector[]
    };

    // TODO: better document here. maybe use some ascii chart
    if (script[1] <= OP_DATA_75) {
        // script = OP_RETURN OP_DATA_<len> DATA
        //          |      2 bytes         |  the rest |
        return vector_slice(&script, 2, script.length())
    };
    if (script[1] == OP_PUSHDATA1) {
        // script = OP_RETURN OP_PUSHDATA1 <1 bytes>    DATA
        //          |      4 bytes                  |  the rest |
        return vector_slice(&script, 3, script.length())
    };
    if (script[1] == OP_PUSHDATA2) {
        // script = OP_RETURN OP_PUSHDATA2 <2 bytes>   DATA
        //          |      4 bytes                  |  the rest |
        return vector_slice(&script, 4, script.length())
    };
    // script = OP_RETURN OP_PUSHDATA4 <4-bytes> DATA
    //          |      6 bytes                  |  the rest |
    vector_slice(&script, 6, script.length())
}
