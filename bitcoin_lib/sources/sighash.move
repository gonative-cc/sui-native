// SPDX-License-Identifier: MPL-2.0

module bitcoin_lib::sighash;

use bitcoin_lib::crypto::hash256;
use bitcoin_lib::encoding::{u32_to_le_bytes, zerohash_32bytes, script_to_var_bytes};
use bitcoin_lib::input;
use bitcoin_lib::output;
use bitcoin_lib::tx::{Self, Transaction};

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
const SIGHASH_ANYONECANPAY_FLAG: u8 = 0x80;

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
    let hash_prevouts: vector<u8> = if ((sighash_type & SIGHASH_ANYONECANPAY_FLAG) == 0) {
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
        (sighash_type & SIGHASH_ANYONECANPAY_FLAG) == 0 &&
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
// TODO: add a test case where user spends two UTXOs
