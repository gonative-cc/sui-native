// SPDX-License-Identifier: MPL-2.0

module bitcoin_lib::output;

use bitcoin_lib::encoding::{u64_to_le_bytes, u64_to_varint_bytes, le_bytes_to_u64};
use bitcoin_lib::opcode;
use bitcoin_lib::reader::Reader;
use bitcoin_lib::script;

/// Represents a Bitcoin transaction output (TxOut).
///
/// A transaction output contains:
/// - amount: The value in satoshis (1/100,000,000 of a Bitcoin) to be transferred
/// - amount_bytes: The 8-byte little-endian representation of the amount
/// - script_pubkey: The locking script that defines conditions for spending this output
///
/// The script_pubkey determines what conditions must be met to spend this output,
/// such as requiring a specific signature, multi-signature, or other conditions.
public struct Output has copy, drop, store {
    amount: u64,
    amount_bytes: vector<u8>,
    script_pubkey: vector<u8>,
}

/// Creates a new Bitcoin transaction output.
///
/// Parameters:
/// - amount: The value in satoshis to be sent to this output
/// - script_pubkey: The locking script that defines spending conditions
///
/// Returns: A new Output struct with the specified amount and script
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

/// Checks if the output is a Pay-to-Script-Hash (P2SH) output.
/// P2SH format: OP_HASH160 <20-byte script hash> OP_EQUAL
/// Used for complex spending conditions where the script is revealed at spending time.
/// Returns true if the output's script_pubkey matches P2SH pattern.
public fun is_P2SH(output: &Output): bool {
    script::is_P2SH(output.script_pubkey)
}

/// Checks if the output is a Pay-to-Witness-Script-Hash (P2WSH) output.
/// P2WSH format: OP_0 <32-byte script hash>
/// Native SegWit output for complex spending conditions.
/// Returns true if the output's script_pubkey matches P2WSH pattern.
public fun is_P2WSH(output: &Output): bool {
    script::is_P2WSH(output.script_pubkey)
}

/// Checks if the output is a Pay-to-Public-Key-Hash (P2PKH) output.
/// P2PKH format: OP_DUP OP_HASH160 <20-byte pubkey hash> OP_EQUALVERIFY OP_CHECKSIG
/// Legacy output type that pays to a Bitcoin address.
/// Returns true if the output's script_pubkey matches P2PKH pattern.
public fun is_P2PKH(output: &Output): bool {
    script::is_P2PKH(output.script_pubkey)
}

/// Checks if the output is an OP_RETURN (null data) output.
/// OP_RETURN format: OP_RETURN <data>
/// Used for embedding arbitrary data in the blockchain, these outputs are unspendable.
/// Returns true if the output's script_pubkey starts with OP_RETURN.
public fun is_op_return(output: &Output): bool {
    script::is_op_return(output.script_pubkey)
}

/// Checks if the output is a Pay-to-Witness-Public-Key-Hash (P2WPKH) output.
/// P2WPKH format: OP_0 <20-byte pubkey hash>
/// Native SegWit output that pays to a Bitcoin address (cheaper than P2PKH).
/// Returns true if the output's script_pubkey matches P2WPKH pattern.
public fun is_P2WPKH(output: &Output): bool {
    script::is_P2WPKH(output.script_pubkey)
}

/// Checks if the output is a Pay-to-Taproot (P2TR) output.
/// Taproot format: OP_1 <32-byte pubkey>
/// Modern output type supporting both key-path and script-path spending.
/// Returns true if the output's script_pubkey matches Taproot pattern.
public fun is_taproot(output: &Output): bool {
    script::is_taproot(output.script_pubkey)
}

// TODO: add support for additional script address types.

/// Extracts the public key hash (PKH) from P2PKH or P2WPKH outputs.
///
/// For P2PKH: extracts the 20-byte hash from the script
/// For P2WPKH: extracts the 20-byte witness program
///
/// Returns:
/// - Some(vector<u8>): The 20-byte public key hash if extraction succeeds
/// - None<vector<u8>>: Empty option if the output is not P2PKH or P2WPKH
public fun extract_public_key_hash(output: &Output): Option<vector<u8>> {
    script::extract_public_key_hash(output.script_pubkey)
}

/// Extracts the script hash from a P2SH output.
///
/// P2SH outputs contain a 20-byte hash of the redeem script.
/// The actual script is revealed when the output is spent.
///
/// Returns:
/// - Some(vector<u8>): The 20-byte script hash if output is P2SH
/// - None<vector<u8>>: Empty option if the output is not P2SH
public fun extract_script_hash(output: &Output): Option<vector<u8>> {
    script::extract_script_hash(output.script_pubkey)
}

/// Extracts the witness script hash from a P2WSH output.
///
/// P2WSH outputs contain a 32-byte hash of the witness script.
/// Used in native SegWit transactions for complex spending conditions.
///
/// Returns:
/// - Some(vector<u8>): The 32-byte witness script hash if output is P2WSH
/// - None<vector<u8>>: Empty option if the output is not P2WSH
public fun extract_witness_script_hash(output: &Output): Option<vector<u8>> {
    script::extract_witness_script_hash(output.script_pubkey)
}

/// Extracts the Taproot public key from a P2TR output.
///
/// Taproot outputs contain a 32-byte public key that can be spent via:
/// - Key path: using the private key corresponding to the public key
/// - Script path: revealing a Merkle root of alternative scripts
///
/// Returns:
/// - Some(vector<u8>): The 32-byte Taproot public key if output is P2TR
/// - None<vector<u8>>: Empty option if the output is not P2TR
public fun extract_taproot(output: &Output): Option<vector<u8>> {
    script::extract_taproot(output.script_pubkey)
}

/// Extracts the data payload from an OP_RETURN output in a transaction.
///
/// OP_RETURN format: OP_RETURN <data>
/// These outputs are used for embedding arbitrary data in the blockchain and are unspendable.
///
/// Note: This function assumes the transaction is valid and mined, so basic
/// OP_RETURN conditions (like maximum data size) are already satisfied.
///
/// Returns:
/// - Some(vector<u8>): The data payload if output is OP_RETURN
/// - None<vector<u8>>: Empty option if the output is not OP_RETURN
public fun op_return(output: &Output): Option<vector<u8>> {
    script::op_return(output.script_pubkey)
}

/// Decodes a Bitcoin transaction output from raw bytes.
///
/// This function parses the raw binary format of a Bitcoin transaction output:
/// - 8 bytes: amount in satoshis (little-endian)
/// - VarInt: script_pubkey length
/// - Variable: script_pubkey bytes
///
/// Parameters:
/// - r: Reader positioned at the start of the output data
///
/// Returns: A decoded Output struct
public(package) fun decode(r: &mut Reader): Output {
    // Read 8-byte amount (little-endian)
    let amount_bytes = r.read(8);

    // Read script_pubkey length as VarInt
    let script_pubkey_size = r.read_compact_size();

    // Read script_pubkey bytes
    let script_pubkey = r.read(script_pubkey_size);

    Output {
        amount: le_bytes_to_u64(amount_bytes),
        amount_bytes,
        script_pubkey,
    }
}

/// Encodes a Bitcoin transaction output to raw bytes.
///
/// This function serializes an Output struct into the binary format used in
/// Bitcoin transactions:
/// - 8 bytes: amount in satoshis (little-endian)
/// - VarInt: script_pubkey length
/// - Variable: script_pubkey bytes
///
/// Parameters:
/// - output: The Output struct to encode
///
/// Returns: Raw bytes representing the encoded transaction output
public(package) fun encode(output: &Output): vector<u8> {
    let mut raw_output = vector[];

    // Add 8-byte amount (little-endian)
    raw_output.append(output.amount_bytes);

    // Add script_pubkey length as VarInt
    raw_output.append(u64_to_varint_bytes(output.script_pubkey.length()));

    // Add script_pubkey bytes
    raw_output.append(output.script_pubkey);

    raw_output
}
