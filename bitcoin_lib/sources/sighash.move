// SPDX-License-Identifier: MPL-2.0

module bitcoin_lib::sighash;

use bitcoin_lib::crypto::hash256;
use bitcoin_lib::encoding::{
    u32_to_le_bytes,
    zerohash_32bytes,
    script_to_var_bytes,
    u64_to_le_bytes
};
use bitcoin_lib::tx::Transaction;
use std::hash::sha2_256 as sha256;

#[test_only]
use std::unit_test::assert_eq;

// TODO: use macro to create share constants

/// These constants are the values of the official opcodes used on the btc wiki,
/// in bitcoin core and in most if not all other references and software related
/// to handling BTC scripts.
/// https://github.com/btcsuite/btcd/blob/master/txscript/opcode.go
const OP_PUSHBYTES_20: u8 = 0x14; // 20
const OP_DUP: u8 = 0x76; // 118
/// Compare the top two items on the stack and halts the script if they are not equal.
const OP_EQUALVERIFY: u8 = 0x88; // 136
const OP_HASH160: u8 = 0xa9; // 169
// const OP_CODESEPARATOR: u8 = 0xab; // 171
const OP_CHECKSIG: u8 = 0xac; // 172
/// Sighash types
const SIGHASH_ALL: u8 = 0x01;
const SIGHASH_NONE: u8 = 0x02;
const SIGHASH_SINGLE: u8 = 0x03;
const SIGHASH_ANYONECANPAY: u8 = 0x80;
const SIGHASH_DEFAULT: u8 = 0x00;
const SIGHASH_OUTPUT_MASK: u8 = 0x03;
const SIGHASH_INPUT_MASK: u8 = 0x80;

#[error]
const EInvalidPKHLength: vector<u8> = b"PHK length must be 20";

public fun create_p2wpkh_scriptcode(pkh: vector<u8>): vector<u8> {
    assert!(pkh.length() == 20, EInvalidPKHLength);
    let mut script = vector::empty<u8>();
    script.push_back(OP_DUP);
    script.push_back(OP_HASH160);
    script.push_back(OP_PUSHBYTES_20);
    script.append(pkh);
    script.push_back(OP_EQUALVERIFY);
    script.push_back(OP_CHECKSIG);
    script
}

/// Constructs the BIP143 preimage for the Segwit hash signature.
/// https://learnmeabitcoin.com/technical/keys/signature/ -> Segwit Algorithm
public fun create_segwit_preimage(
    transaction: &Transaction,
    input_idx_to_sign: u64,
    input_script: &vector<u8>, // For P2WPKH: 0x1976a914{PKH}88ac. For P2WSH: the witnessScript.
    amount_spent_by_this_input: vector<u8>,
    sighash_type: u8,
): vector<u8> {
    let mut preimage = vector[];
    preimage.append(transaction.version());

    // HASH256(concatenation of all (input.tx_id + input.vout))
    let hash_prevouts: vector<u8> = if ((sighash_type & SIGHASH_ANYONECANPAY) == 0) {
        let mut all_prevouts_concat = vector[];
        transaction.inputs().length().do!(|i| {
            let input_ref = transaction.input_at(i);
            all_prevouts_concat.append(input_ref.tx_id()); //already a u32_le_bytes
            all_prevouts_concat.append(input_ref.vout());
        });
        hash256(all_prevouts_concat)
    } else {
        zerohash_32bytes() // 32 zero bytes if ANYONECANPAY
    };
    preimage.append(hash_prevouts);

    // HASH256(concatenation of all input.sequence)
    let base_sighash_type = sighash_type & 0x1f; // Mask off ANYONECANPAY bit

    let hash_sequence = if (
        (sighash_type & SIGHASH_ANYONECANPAY) == 0 &&
            base_sighash_type != SIGHASH_NONE &&
            base_sighash_type != SIGHASH_SINGLE
    ) {
        let mut all_sequences_concatenated = vector[];
        transaction.inputs().length().do!(|i| {
            all_sequences_concatenated.append(transaction.input_at(i).sequence());
        });
        hash256(all_sequences_concatenated)
    } else {
        zerohash_32bytes()
    };
    preimage.append(hash_sequence);

    // Serialize the TXID and VOUT for the input were signing
    let current_input = transaction.input_at(input_idx_to_sign);
    preimage.append(current_input.tx_id());
    preimage.append(current_input.vout());

    preimage.append(script_to_var_bytes(input_script));
    preimage.append(amount_spent_by_this_input);
    preimage.append(current_input.sequence());

    // HASH256(concatenation of all (output.value + output.script_pub_key_with_len))
    let hash_outputs: vector<u8> = if (
        base_sighash_type != SIGHASH_NONE && base_sighash_type != SIGHASH_SINGLE
    ) {
        let mut all_outputs_concat = vector[];
        transaction.outputs().length().do!(|i| {
            let output_ref = transaction.output_at(i);
            all_outputs_concat.append(output_ref.amount_bytes());
            all_outputs_concat.append(
                script_to_var_bytes(&output_ref.script_pubkey()),
            );
        });
        hash256(all_outputs_concat)
    } else if (
        base_sighash_type == SIGHASH_SINGLE && input_idx_to_sign < transaction.outputs().length()
    ) {
        let output_to_sign = transaction.output_at(input_idx_to_sign);
        let mut single_output_concatenated = vector[];
        single_output_concatenated.append(output_to_sign.amount_bytes());
        single_output_concatenated.append(
            script_to_var_bytes(&output_to_sign.script_pubkey()),
        );
        hash256(single_output_concatenated)
    } else {
        zerohash_32bytes()
    };
    preimage.append(hash_outputs);
    preimage.append(transaction.locktime());
    preimage.append(u32_to_le_bytes((sighash_type as u32)));
    preimage //Complete preimage data to be hashed (Once and later edcsa::verify will hash second time)
}

// support SIGHASH_ALL only
public fun taproot_sighash_keyspending_path(
    tx: &Transaction,
    input_idx_to_sign: u32,
    previous_pubscripts: vector<vector<u8>>,
    values: vector<u64>,
    hash_type: u8, // right now only SIGNASH ALL
    leaf_hash: Option<vector<u8>>,
    annex: Option<vector<u8>>, // ???
): vector<u8> {
    let output_type = if (hash_type  == SIGHASH_DEFAULT) {
        SIGHASH_ALL
    } else {
        hash_type & SIGHASH_OUTPUT_MASK
    };
    let input_type = hash_type & SIGHASH_INPUT_MASK;
    let is_any_one_can_pay = input_type == SIGHASH_ANYONECANPAY;
    let is_none = output_type == SIGHASH_NONE;
    let is_single = output_type == SIGHASH_SINGLE;

    let mut hash_prevouts = vector::empty();
    let mut hash_amounts = vector::empty();
    let mut hash_script_pubkeys = vector::empty();
    let mut hash_sequences = vector::empty();
    let mut hash_outputs = vector::empty();
    if (!is_any_one_can_pay) {
        tx.inputs().do!(|input| {
            hash_prevouts.append(input.tx_id());
            hash_prevouts.append(input.vout());
            hash_sequences.append(input.sequence());
        });
        hash_prevouts = sha256(hash_prevouts);
        hash_sequences = sha256(hash_sequences);
        values.do!(|value| {
            hash_amounts.append(u64_to_le_bytes(value));
        });
        hash_amounts = sha256(hash_amounts);

        previous_pubscripts.do!(|pub_scripts| {
            hash_script_pubkeys.append(pub_scripts)
        });
        hash_script_pubkeys = sha256(hash_script_pubkeys);
    };
    if ((is_none || is_single) == false) {
        tx.outputs().do!(|output| {
            hash_outputs.append(output.amount_bytes());
            hash_outputs.append(output.script_pubkey());
        });
        hash_outputs = sha256(hash_outputs);
    } else if (is_single && (input_idx_to_sign as u64 < tx.outputs().length())) {
        let output = tx.output_at(input_idx_to_sign as u64);
        hash_outputs.append(output.amount_bytes());
        hash_outputs.append(output.script_pubkey());
        hash_outputs = sha256(hash_outputs);
    };
    let mut preimage = vector::empty();
    preimage.append(vector[hash_type]);
    preimage.append(tx.version());
    preimage.append(hash_prevouts);
    preimage.append(hash_amounts);
    preimage.append(hash_script_pubkeys);
    preimage.append(hash_sequences);
    if ((is_none || is_single) == false) {
        preimage.append(hash_outputs);
    };
    let spend_type: u8 = if (leaf_hash.is_some()) 2
    else 0
             + if (annex.is_some()) 1 else 0;
    preimage.push_back(spend_type);
    if (is_any_one_can_pay) {
        let inp = tx.input_at(input_idx_to_sign as u64);
        preimage.append(inp.tx_id());
        preimage.append(inp.vout());
        preimage.append(u64_to_le_bytes(values[input_idx_to_sign as u64]));
        preimage.append(
            script_to_var_bytes(&previous_pubscripts[input_idx_to_sign as u64]),
        );
    } else {
        preimage.append(u32_to_le_bytes(input_idx_to_sign));
    };

    // annex always none on BTC now
    if (annex.is_some()) {};

    if (is_single) {
        preimage.append(hash_outputs);
    };

    // use taproot spending path

    if (leaf_hash.is_some()) {
        preimage.append(*leaf_hash.borrow());
        preimage.push_back(0);
        preimage.append(x"ffffffff");
    };
    // sha256("TapSighash") = f40a48df4b2a70c8b4924bf2654661ed3d95fd66a313eb87237597c628e4a031
    let mut hash_data = x"f40a48df4b2a70c8b4924bf2654661ed3d95fd66a313eb87237597c628e4a031";
    hash_data.push_back(0x00);
    hash_data.append(preimage);
    sha256(hash_data)
}

#[test_only]
use bitcoin_lib::{input, output, tx};
#[test]
fun test_create_segwit_preimage_lmb_example() {
    // all the data for the test copied from the exmaple https://learnmeabitcoin.com/technical/keys/signature/
    let expected_preimage =
        x"02000000cbfaca386d65ea7043aaac40302325d0dc7391a73b585571e28d3287d6b162033bb13029ce7b1f559ef5e747fcac439f1455a2ec7c5f09b72290795e70665044ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a010000001976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac3075000000000000ffffffff900a6c6ff6cd938bf863e50613a4ed5fb1661b78649fe354116edaf5d4abb9520000000001000000";

    let input_tx_id_bytes = x"ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a";

    let test_inputs = vector[
        input::new(
            input_tx_id_bytes,
            x"01000000",
            vector[], // empty script_sig for P2WPKH input
            x"ffffffff",
        ),
    ];

    let test_outputs = vector[
        output::new(
            20000,
            x"76a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac",
        ),
    ];

    let test_tx = tx::new(
        x"02000000",
        option::some(00u8),
        option::some(01u8),
        test_inputs,
        test_outputs,
        vector[],
        x"00000000",
        vector[],
    );

    let input_idx_to_sign = 0u64;
    let input_script = x"76a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    let amount_spent_by_this_input = x"3075000000000000";
    let sighash_type = SIGHASH_ALL; // 0x01

    let result_preimage = create_segwit_preimage(
        &test_tx,
        input_idx_to_sign,
        &input_script,
        amount_spent_by_this_input,
        sighash_type,
    );

    assert_eq!(result_preimage, expected_preimage);
}

#[test]
fun test_create_p2wpkh_scriptcode() {
    // data taken from https://learnmeabitcoin.com/technical/keys/signature/
    let pkh = x"aa966f56de599b4094b61aa68a2b3df9e97e9c48";
    let expected_script_code = x"76a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    assert_eq!(create_p2wpkh_scriptcode(pkh), expected_script_code);
}

#[test]
fun test_taproot_sighash() {}
// TODO: add a test case where user spends two UTXOs
//
