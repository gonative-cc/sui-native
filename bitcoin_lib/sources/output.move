// SPDX-License-Identifier: MPL-2.0

module bitcoin_lib::output;

use bitcoin_lib::encoding::{u64_to_le_bytes, u64_to_varint_bytes, le_bytes_to_u64};
use bitcoin_lib::opcode;
use bitcoin_lib::reader::Reader;
use bitcoin_lib::vector_utils::vector_slice;

// === BTC script opcodes are now in bitcoin_lib::opcode module ===

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

public fun is_P2SH(output: &Output): bool {
    let script = output.script_pubkey();
    script.length() == 23 &&
	script[0] == opcode::OP_HASH160!() &&
	script[1] == opcode::OP_PUSHBYTES_20!() &&
	script[22] == opcode::OP_EQUAL!()
}

public fun is_P2WSH(output: &Output): bool {
    let script = output.script_pubkey();
    script.length() == 34 &&
	script[0] == opcode::OP_0!() &&
	script[1] == opcode::OP_PUSHBYTES_32!()
}

public fun is_P2PHK(output: &Output): bool {
    let script = output.script_pubkey();

    script.length() == 25 &&
		script[0] == opcode::OP_DUP!() &&
		script[1] == opcode::OP_HASH160!() &&
		script[2] == opcode::OP_PUSHBYTES_20!() &&
		script[23] == opcode::OP_EQUALVERIFY!() &&
		script[24] == opcode::OP_CHECKSIG!()
}

public fun is_op_return(output: &Output): bool {
    let script = output.script_pubkey;
    script.length() > 0 && script[0] == opcode::OP_RETURN!()
}

public fun is_P2WPHK(output: &Output): bool {
    let script = output.script_pubkey;
    script.length() == 22 &&
        script[0] == opcode::OP_0!() &&
        script[1] == opcode::OP_PUSHBYTES_20!()
}

public fun is_taproot(output: &Output): bool {
    let script = output.script_pubkey;
    script.length() == 34 &&
	script[0] == opcode::OP_1!() &&
	script[1] == opcode::OP_PUSHBYTES_32!()
}

// TODO: add support script addresses.
// TODO: check and verify the address to make sure we support it. Return error otherwise
/// extracts public key hash (PKH) from the output in P2PHK or P2WPKH
/// returns an empty vector in case it was not able to extract it
public fun extract_public_key_hash(output: &Output): Option<vector<u8>> {
    let script = output.script_pubkey;
    if (output.is_P2PHK()) {
        return option::some(vector_slice(&script, 3, 23))
    } else if (output.is_P2WPHK()) {
        return option::some(vector_slice(&script, 2, 22))
    };
    option::none()
}

public fun extract_script_hash(output: &Output): Option<vector<u8>> {
    let script = output.script_pubkey;
    if (output.is_P2SH()) {
        option::some(vector_slice(&script, 2, 22))
    } else {
        option::none()
    }
}

public fun extract_witness_script_hash(output: &Output): Option<vector<u8>> {
    let script = output.script_pubkey;
    if (output.is_P2WSH()) {
        option::some(vector_slice(&script, 2, 34))
    } else {
        option::none()
    }
}

public fun extract_taproot(output: &Output): Option<vector<u8>> {
    let script = output.script_pubkey;
    if (output.is_taproot()) {
        option::some(vector_slice(&script, 2, 34))
    } else {
        option::none()
    }
}

/// Extracts the data payload from an OP_RETURN output in a transaction.
/// script = OP_RETURN <data>.
/// If transaction is mined, then this must pass basic conditions
/// including the conditions for OP_RETURN script.
/// This is why we only return the message without check size message.
public fun op_return(output: &Output): Option<vector<u8>> {
    let script = output.script_pubkey;

    if (script.length() == 1) {
        return option::none()
    };

    // TODO: better document here. maybe use some ascii chart
    if (script[1] <= opcode::OP_PUSHBYTES_75!()) {
        // script = OP_RETURN OP_DATA_<len> DATA
        //          |      2 bytes         |  the rest |
        return option::some(vector_slice(&script, 2, script.length()))
    };
    if (script[1] == opcode::OP_PUSHDATA1!()) {
        // script = OP_RETURN OP_PUSHDATA1 <1 bytes>    DATA
        //          |      3 bytes                  |  the rest |
        return option::some(vector_slice(&script, 3, script.length()))
    };
    if (script[1] == opcode::OP_PUSHDATA2!()) {
        // script = OP_RETURN OP_PUSHDATA2 <2 bytes>   DATA
        //          |      4 bytes                  |  the rest |
        return option::some(vector_slice(&script, 4, script.length()))
    };
    // script = OP_RETURN OP_PUSHDATA4 <4-bytes> DATA
    //          |      6 bytes                  |  the rest |
    option::some(vector_slice(&script, 6, script.length()))
}

public(package) fun decode(r: &mut Reader): Output {
    let amount_bytes = r.read(8);
    let script_pubkey_size = r.read_compact_size();
    let script_pubkey = r.read(script_pubkey_size);

    Output {
        amount: le_bytes_to_u64(amount_bytes),
        amount_bytes,
        script_pubkey,
    }
}

public(package) fun encode(output: &Output): vector<u8> {
    let mut raw_output = vector[];
    raw_output.append(output.amount_bytes);
    raw_output.append(u64_to_varint_bytes(output.script_pubkey.length()));
    raw_output.append(output.script_pubkey);
    raw_output
}
