module bitcoin_lib::script;

use bitcoin_lib::opcode;
use bitcoin_lib::vector_utils::vector_slice;
use std::hash::sha2_256;

/// Checks if the script is a Pay-to-Script-Hash (P2SH) output.
/// P2SH format: OP_HASH160 OP_DATA_20 <20-byte-hash> OP_EQUAL
/// Returns true if the script matches the P2SH pattern, false otherwise.
public fun is_P2SH(script: vector<u8>): bool {
    script.length() == 23 &&
	script[0] == opcode::OP_HASH160!() &&
	script[1] == opcode::OP_PUSHBYTES_20!() &&
	script[22] == opcode::OP_EQUAL!()
}

/// Checks if the script is a Pay-to-Witness-Script-Hash (P2WSH) output.
/// P2WSH format: OP_0 OP_DATA_32 <32-byte-hash>
/// Returns true if the script matches the P2WSH pattern, false otherwise.
public fun is_P2WSH(script: vector<u8>): bool {
    script.length() == 34 &&
	script[0] == opcode::OP_0!() &&
	script[1] == opcode::OP_PUSHBYTES_32!()
}

/// Checks if the script is a Pay-to-Public-Key-Hash (P2PKH) output.
/// P2PKH format: OP_DUP OP_HASH160 OP_DATA_20 <20-byte-hash> OP_EQUALVERIFY OP_CHECKSIG
/// Returns true if the script matches the P2PKH pattern, false otherwise.
public fun is_P2PKH(script: vector<u8>): bool {
    script.length() == 25 &&
		script[0] == opcode::OP_DUP!() &&
		script[1] == opcode::OP_HASH160!() &&
		script[2] == opcode::OP_PUSHBYTES_20!() &&
		script[23] == opcode::OP_EQUALVERIFY!() &&
		script[24] == opcode::OP_CHECKSIG!()
}

/// Checks if the script is an OP_RETURN output.
/// OP_RETURN outputs are used to store arbitrary data on the blockchain and are unspendable.
/// Returns true if the script starts with OP_RETURN, false otherwise.
public fun is_op_return(script: vector<u8>): bool {
    script.length() > 0 && script[0] == opcode::OP_RETURN!()
}

/// Checks if the script is a Pay-to-Witness-Public-Key-Hash (P2WPKH) output.
/// P2WPKH format: OP_0 OP_DATA_20 <20-byte-hash>
/// Returns true if the script matches the P2WPKH pattern, false otherwise.
public fun is_P2WPKH(script: vector<u8>): bool {
    script.length() == 22 &&
        script[0] == opcode::OP_0!() &&
        script[1] == opcode::OP_PUSHBYTES_20!()
}

/// Checks if the script is a Taproot (P2TR) output.
/// Taproot format: OP_1 OP_DATA_32 <32-byte-public-key>
/// Returns true if the script matches the Taproot pattern, false otherwise.
public fun is_taproot(script: vector<u8>): bool {
    script.length() == 34 &&
	script[0] == opcode::OP_1!() &&
	script[1] == opcode::OP_PUSHBYTES_32!()
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

    if (script[1] <= opcode::OP_PUSHBYTES_75!()) {
        // Format: OP_RETURN OP_DATA_<len> DATA
        // Pos:     0        1           2+
        // Bytes:   1        1           len
        return option::some(vector_slice(&script, 2, script.length()))
    };
    if (script[1] == opcode::OP_PUSHDATA1!()) {
        // Format: OP_RETURN OP_PUSHDATA1 <len> DATA
        // Pos:     0        1            2    3+
        // Bytes:   1        1            1    len
        return option::some(vector_slice(&script, 3, script.length()))
    };
    if (script[1] == opcode::OP_PUSHDATA2!()) {
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

#[error]
const EInvalidMerkleHashLength: vector<u8> = b"Invalid merkle hash length";

const HASH_LENGTH: u64 = 32;

/// Tagged hash helper function.
/// Computes: hash(tag) = SHA256(SHA256(tag) || SHA256(tag))
/// Used for Taproot tagged hashes: TapLeaf, TapBranch, TapTweak, TapSighash.
///
/// # Arguments
/// * `tag` - Tag string (e.g., "TapLeaf", "TapBranch")
/// * `data` - Data to hash
///
/// # Returns
/// * 32-byte tagged hash
fun tag_hash(tag: vector<u8>, data: vector<u8>): vector<u8> {
    let tag_hash = sha2_256(tag); // use constant
    let mut hash_data = tag_hash;
    hash_data.append(tag_hash);
    hash_data.append(data);
    sha2_256(hash_data)
}

/// Computes TapLeaf tagged hash.
/// Used for leaf nodes in Taproot script merkle trees (MAST).
/// Formula: tag_hash("TapLeaf", version || script)
///
/// # Returns 32-byte TapLeaf hash
public fun tap_leaf_hash(version: u8, script: vector<u8>): vector<u8> {
    let mut data = vector[version];
    data.append(script);
    tag_hash(b"TapLeaf", data)
}

/// Computes TapBranch tagged hash for internal nodes in Taproot script merkle trees (MAST).
/// Follows BIP-341 specification.
/// Formula: tag_hash("TapBranch", smaller || larger)
/// where smaller and larger are sorted lexicographically.
///
/// Arguments
/// * `a` - First child hash (32 bytes)
/// * `b` - Second child hash (32 bytes)
/// Returns 32-byte TapBranch hash
public fun tap_branch_hash(a: vector<u8>, b: vector<u8>): vector<u8> {
    let cmp = vector_compare(&a, &b);
    let (smaller, larger) = if (cmp == 1) {
        (a, b)
    } else {
        (b, a)
    };
    let mut data = smaller;
    data.append(larger);
    tag_hash(b"TapBranch", data)
}

/// Compares two vectors lexicographically.
/// Returns:
/// * 1 if a < b
/// * 0 if a == b
/// * 2 if a > b
fun vector_compare(a: &vector<u8>, b: &vector<u8>): u8 {
    let min_len = a.length().min(b.length());
    let mut i = 0;
    while (i < min_len) {
        if (a[i] < b[i]) {
            return 1
        } else if (a[i] > b[i]) {
            return 2
        };
        i = i + 1;
    };
    if (a.length() < b.length()) {
        1
    } else if (a.length() > b.length()) {
        2
    } else {
        0
    }
}

/// Verifies that a script hash belongs to a Taproot script merkle tree (MAST)
/// using a merkle proof with Taproot tagged hashing based on BIP-341.
///
/// Note: TapBranch uses lexicographic ordering, so we don't need to track
/// the leaf index. The merkle path alone determines the computation.
///
/// Arguments
/// * `script_hash` - The script hash (leaf) to verify (32 bytes)
/// * `merkle_path` - Vector of sibling hashes from leaf to root
/// * `script_merkle_root` - Expected merkle root of the script tree (32 bytes)
/// Returns `true` if the script hash is in the merkle tree, `false` otherwise
/// ```
public fun verify_script_merkle_proof(
    script_hash: vector<u8>,
    merkle_path: vector<vector<u8>>,
    script_merkle_root: vector<u8>,
): bool {
    assert!(script_hash.length() == HASH_LENGTH, EInvalidMerkleHashLength);
    assert!(script_merkle_root.length() == HASH_LENGTH, EInvalidMerkleHashLength);

    let computed_root = merkle_path.fold!(script_hash, |child_hash, sibling_hash| {
        assert!(sibling_hash.length() == HASH_LENGTH, EInvalidMerkleHashLength);
        tap_branch_hash(child_hash, sibling_hash)
    });
    computed_root == script_merkle_root
}
