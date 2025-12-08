module bitcoin_lib::script;

use bitcoin_lib::vector_utils::vector_slice;

// === BTC script opcodes ===
/// An empty array of bytes is pushed onto the stack. (This is not a no-op: an item is added to the stack.)
const OP_0: u8 = 0x00;
/// Push the number 1 onto the stack
const OP_1: u8 = 0x51;
/// Duplicates the top stack item
const OP_DUP: u8 = 0x76;
/// Pop the top stack item and push its RIPEMD(SHA256(top item)) hash
const OP_HASH160: u8 = 0xa9;
/// Push the next 20 bytes as an array onto the stack
const OP_DATA_20: u8 = 0x14;
/// Push the next 32 bytes as an array onto the stack
const OP_DATA_32: u8 = 0x20;
/// Returns 1 if the inputs are exactly equal, 0 otherwise
const OP_EQUAL: u8 = 0x87;
/// Returns success if the inputs are exactly equal, failure otherwise
const OP_EQUALVERIFY: u8 = 0x88;
/// https://en.bitcoin.it/wiki/OP_CHECKSIG pushing 1/0 for success/failure
const OP_CHECKSIG: u8 = 0xac;
/// nulldata script - marks transaction output as unspendable
const OP_RETURN: u8 = 0x6a;
/// Read the next 4 bytes as N. Push the next N bytes as an array onto the stack.
const OP_PUSHDATA4: u8 = 0x4e;
/// Read the next 2 bytes as N. Push the next N bytes as an array onto the stack.
const OP_PUSHDATA2: u8 = 0x4d;
/// Read the next byte as N. Push the next N bytes as an array onto the stack.
const OP_PUSHDATA1: u8 = 0x4c;
/// Push the next 75 bytes onto the stack.
const OP_DATA_75: u8 = 0x4b;

/// Checks if the script is a Pay-to-Script-Hash (P2SH) output.
/// P2SH format: OP_HASH160 OP_DATA_20 <20-byte-hash> OP_EQUAL
/// Returns true if the script matches the P2SH pattern, false otherwise.
public fun is_P2SH(script: vector<u8>): bool {
    script.length() == 23 &&
	script[0] == OP_HASH160 &&
	script[1] == OP_DATA_20 &&
	script[22] == OP_EQUAL
}

/// Checks if the script is a Pay-to-Witness-Script-Hash (P2WSH) output.
/// P2WSH format: OP_0 OP_DATA_32 <32-byte-hash>
/// Returns true if the script matches the P2WSH pattern, false otherwise.
public fun is_P2WSH(script: vector<u8>): bool {
    script.length() == 34 &&
	script[0] == OP_0 &&
	script[1] == OP_DATA_32
}

/// Checks if the script is a Pay-to-Public-Key-Hash (P2PKH) output.
/// P2PKH format: OP_DUP OP_HASH160 OP_DATA_20 <20-byte-hash> OP_EQUALVERIFY OP_CHECKSIG
/// Returns true if the script matches the P2PKH pattern, false otherwise.
public fun is_P2PKH(script: vector<u8>): bool {
    script.length() == 25 &&
		script[0] == OP_DUP &&
		script[1] == OP_HASH160 &&
		script[2] == OP_DATA_20 &&
		script[23] == OP_EQUALVERIFY &&
		script[24] == OP_CHECKSIG
}

/// Checks if the script is an OP_RETURN output.
/// OP_RETURN outputs are used to store arbitrary data on the blockchain and are unspendable.
/// Returns true if the script starts with OP_RETURN, false otherwise.
public fun is_op_return(script: vector<u8>): bool {
    script.length() > 0 && script[0] == OP_RETURN
}

/// Checks if the script is a Pay-to-Witness-Public-Key-Hash (P2WPKH) output.
/// P2WPKH format: OP_0 OP_DATA_20 <20-byte-hash>
/// Returns true if the script matches the P2WPKH pattern, false otherwise.
public fun is_P2WPKH(script: vector<u8>): bool {
    script.length() == 22 &&
        script[0] == OP_0 &&
        script[1] == OP_DATA_20
}

/// Checks if the script is a Taproot (P2TR) output.
/// Taproot format: OP_1 OP_DATA_32 <32-byte-public-key>
/// Returns true if the script matches the Taproot pattern, false otherwise.
public fun is_taproot(script: vector<u8>): bool {
    script.length() == 34 &&
	script[0] == OP_1 &&
	script[1] == OP_DATA_32
}

// TODO: add support script addresses.
// TODO: check and verify the address to make sure we support it. Return error otherwise

/// Extracts the public key hash (PKH) from a P2PKH or P2WPKH script.
/// For P2PKH: extracts the 20-byte hash from position 3 to 23
/// For P2WPKH: extracts the 20-byte hash from position 2 to 22
/// Returns Some(vector<u8>) with the hash if found, None otherwise.
public fun extract_public_key_hash(script: vector<u8>): Option<vector<u8>> {
    if (is_P2PKH(script)) {
        return option::some(vector_slice(&script, 3, 23))
    } else if (is_P2WPKH(script)) {
        return option::some(vector_slice(&script, 2, 22))
    };
    option::none()
}

/// Extracts the script hash from a P2SH script.
/// P2SH format: OP_HASH160 OP_DATA_20 <20-byte-script-hash> OP_EQUAL
/// Extracts the 20-byte hash from position 2 to 22
/// Returns Some(vector<u8>) with the script hash if found, None otherwise.
public fun extract_script_hash(script: vector<u8>): Option<vector<u8>> {
    if (is_P2SH(script)) {
        option::some(vector_slice(&script, 2, 22))
    } else {
        option::none()
    }
}

/// Extracts the witness script hash from a P2WSH script.
/// P2WSH format: OP_0 OP_DATA_32 <32-byte-witness-script-hash>
/// Extracts the 32-byte hash from position 2 to 34
/// Returns Some(vector<u8>) with the witness script hash if found, None otherwise.
public fun extract_witness_script_hash(script: vector<u8>): Option<vector<u8>> {
    if (is_P2WSH(script)) {
        option::some(vector_slice(&script, 2, 34))
    } else {
        option::none()
    }
}

/// Extracts the Taproot public key from a P2TR script.
/// Taproot format: OP_1 OP_DATA_32 <32-byte-public-key>
/// Extracts the 32-byte public key from position 2 to 34
/// Returns Some(vector<u8>) with the Taproot public key if found, None otherwise.
public fun extract_taproot(script: vector<u8>): Option<vector<u8>> {
    if (is_taproot(script)) {
        option::some(vector_slice(&script, 2, 34))
    } else {
        option::none()
    }
}

/// Extracts the data payload from an OP_RETURN output in a transaction.
/// OP_RETURN format: OP_RETURN <data>
/// The data can be encoded in several ways:
/// - OP_RETURN OP_DATA_<len> DATA (for data ≤ 75 bytes)
/// - OP_RETURN OP_PUSHDATA1 <1-byte-length> DATA (for data <= 255 bytes)
/// - OP_RETURN OP_PUSHDATA2 <2-byte-length> DATA (for data <= 65535 bytes)
/// - OP_RETURN OP_PUSHDATA4 <4-byte-length> DATA (for data <= 2^32-1 bytes)
///
/// If the transaction is mined, it must pass basic conditions including OP_RETURN script conditions.
/// This function extracts the data payload without performing size validation.
/// Returns Some(vector<u8>) with the data payload if found, None otherwise.
public fun op_return(script: vector<u8>): Option<vector<u8>> {
    if (script.length() == 1) {
        return option::none()
    };

    if (script[1] <= OP_DATA_75) {
        // Format: OP_RETURN OP_DATA_<len> DATA
        // Pos:     0        1           2+
        // Bytes:   1        1           len
        return option::some(vector_slice(&script, 2, script.length()))
    };
    if (script[1] == OP_PUSHDATA1) {
        // Format: OP_RETURN OP_PUSHDATA1 <len> DATA
        // Pos:     0        1            2    3+
        // Bytes:   1        1            1    len
        return option::some(vector_slice(&script, 3, script.length()))
    };
    if (script[1] == OP_PUSHDATA2) {
        // Format: OP_RETURN OP_PUSHDATA2 <len-len> DATA
        // Pos:     0        1            2-3   4+
        // Bytes:   1        1            2     len
        return option::some(vector_slice(&script, 4, script.length()))
    };
    // Format: OP_RETURN OP_PUSHDATA4 <len-len-len-len> DATA
    // Pos:     0        1            2-5         6+
    // Bytes:   1        1            4           len
    option::some(vector_slice(&script, 6, script.length()))
}
