// SPDX-License-Identifier: MPL-2.0

module bitcoin_lib::output;

use bitcoin_lib::encoding::{u64_to_le_bytes, u64_to_varint_bytes, le_bytes_to_u64};
use bitcoin_lib::reader::Reader;
use bitcoin_lib::script;

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
    script::is_P2SH(output.script_pubkey)
}

public fun is_P2WSH(output: &Output): bool {
    script::is_P2WSH(output.script_pubkey)
}

public fun is_P2PHK(output: &Output): bool {
    script::is_P2PHK(output.script_pubkey)
}

public fun is_op_return(output: &Output): bool {
    script::is_op_return(output.script_pubkey)
}

public fun is_P2WPHK(output: &Output): bool {
    script::is_P2WPHK(output.script_pubkey)
}

public fun is_taproot(output: &Output): bool {
    script::is_taproot(output.script_pubkey)
}

// TODO: add support script addresses.
// TODO: check and verify the address to make sure we support it. Return error otherwise
/// extracts public key hash (PKH) from the output in P2PHK or P2WPKH
/// returns an empty vector in case it was not able to extract it
public fun extract_public_key_hash(output: &Output): Option<vector<u8>> {
    script::extract_public_key_hash(output.script_pubkey)
}

public fun extract_script_hash(output: &Output): Option<vector<u8>> {
    script::extract_script_hash(output.script_pubkey)
}

public fun extract_witness_script_hash(output: &Output): Option<vector<u8>> {
    script::extract_witness_script_hash(output.script_pubkey)
}

public fun extract_taproot(output: &Output): Option<vector<u8>> {
    script::extract_taproot(output.script_pubkey)
}

/// Extracts the data payload from an OP_RETURN output in a transaction.
/// script = OP_RETURN <data>.
/// If transaction is mined, then this must pass basic conditions
/// including the conditions for OP_RETURN script.
/// This is why we only return the message without check size message.
public fun op_return(output: &Output): Option<vector<u8>> {
    script::op_return(output.script_pubkey)
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
