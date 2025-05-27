module bitcoin_executor::sighash;

use bitcoin_executor::utils;
use std::hash::sha2_256;
use std::unit_test::assert_eq;

const SIGHASH_ALL: u8 = 0x01;
const SIGHASH_NONE: u8 = 0x02;
const SIGHASH_SINGLE: u8 = 0x03;
const SIGHASH_ANYONECANPAY_FLAG: u8 = 0x80;

/// Inputs in btc transaction
public struct Input has copy, drop {
    /// Reference to the output being spent.
    tx_id: vector<u8>,
    vout: u32,
    /// https://learnmeabitcoin.com/technical/transaction/input/scriptsig/
    script_sig: vector<u8>,
    /// tx version
    sequence: u32,
}

public struct Output has copy, drop {
    /// in satoshi
    value: u64,
    /// script that locks the output (scriptPubKey)
    /// https://learnmeabitcoin.com/technical/script/
    script_pub_key: vector<u8>,
}

public struct Tx has copy, drop {
    version: u32,
    inputs: vector<Input>,
    outputs: vector<Output>,
    lock_time: u32,
    witness: vector<u8>,
}

public fun create_bip143_sighash_preimage(
    transaction: &Tx,
    input_idx_being_signed: u64,
    script_code_for_input: &vector<u8>, // For P2WPKH: 0x1976a914{PKH}88ac. For P2WSH: the witnessScript.
    amount_spent_by_this_input: u64,
    sighash_type_byte: u8,
): vector<u8> {
    let mut preimage = vector[];
    preimage.append(utils::u32_to_le_bytes(transaction.version));

    // SHA256(SHA256(concatenation of all (input.tx_id + input.vout)))
    let hash_prevouts: vector<u8>;
    if ((sighash_type_byte & SIGHASH_ANYONECANPAY_FLAG) == 0) {
        let mut all_prevouts_concat = vector[];
        let mut i = 0;
        while (i < transaction.inputs.length()) {
            let input_ref = transaction.inputs.borrow(i);
            all_prevouts_concat.append(input_ref.tx_id); //already a u32_le_bytes
            all_prevouts_concat.append(utils::u32_to_le_bytes(input_ref.vout));
            i = i + 1;
        };
        hash_prevouts = sha2_256(sha2_256(all_prevouts_concat));
    } else {
        hash_prevouts = utils::zerohash_32bytes(); // 32 zero bytes if ANYONECANPAY
    };
    preimage.append(hash_prevouts);

    // SHA256(SHA256(concatenation of all input.sequence))
    let hash_sequence: vector<u8>;
    let base_sighash_type = sighash_type_byte & 0x1f; // Mask off ANYONECANPAY bit

    if (
        (sighash_type_byte & SIGHASH_ANYONECANPAY_FLAG) == 0 &&
            base_sighash_type != SIGHASH_NONE &&
            base_sighash_type != SIGHASH_SINGLE
    ) {
        let mut all_sequences_concatenated = vector[];
        let mut i = 0;
        while (i < transaction.inputs.length()) {
            all_sequences_concatenated.append(
                utils::u32_to_le_bytes(transaction.inputs[i].sequence),
            );
            i = i + 1;
        };
        hash_sequence = sha2_256(sha2_256(all_sequences_concatenated));
    } else {
        hash_sequence = utils::zerohash_32bytes();
    };
    preimage.append(hash_sequence);

    // Serialize the TXID and VOUT for the input were signing
    let current_input = transaction.inputs[input_idx_being_signed];
    preimage.append(current_input.tx_id);
    preimage.append(utils::u32_to_le_bytes(current_input.vout));

    preimage.append(utils::script_to_var_bytes(script_code_for_input));
    preimage.append(utils::u64_to_le_bytes(amount_spent_by_this_input));
    preimage.append(utils::u32_to_le_bytes(current_input.sequence));

    // SHA256(SHA256(concatenation of all (output.value + output.script_pub_key_with_len)))
    let hash_outputs: vector<u8>;
    if (base_sighash_type != SIGHASH_NONE && base_sighash_type != SIGHASH_SINGLE) {
        let mut all_outputs_concat = vector[];
        let mut i = 0;
        while (i < transaction.outputs.length()) {
            let output_ref = transaction.outputs[i];
            all_outputs_concat.append(utils::u64_to_le_bytes(output_ref.value));
            all_outputs_concat.append(utils::script_to_var_bytes(&output_ref.script_pub_key));
            i = i + 1;
        };
        hash_outputs = sha2_256(sha2_256(all_outputs_concat));
    } else if (base_sighash_type == SIGHASH_SINGLE && input_idx_being_signed < transaction.outputs.length()) {
        let output_to_sign = transaction.outputs[input_idx_being_signed];
        let mut single_output_concatenated = vector[];
        single_output_concatenated.append(utils::u64_to_le_bytes(output_to_sign.value));
        single_output_concatenated.append(
            utils::script_to_var_bytes(&output_to_sign.script_pub_key),
        );
        hash_outputs = sha2_256(sha2_256(single_output_concatenated));
    } else {
        hash_outputs = utils::zerohash_32bytes();
    };
    preimage.append(hash_outputs);
    preimage.append(utils::u32_to_le_bytes(transaction.lock_time));
    preimage.append(utils::u32_to_le_bytes((sighash_type_byte as u32)));

    preimage //Complete preimage data to be hashed (Once and later edcsa::verify will hash second time)
}

#[test]
fun test_create_bip143_sighash_preimage_lmb_example() {
    // all the data for the test copied from the exmaple https://learnmeabitcoin.com/technical/keys/signature/
    let expected_preimage =
        x"02000000cbfaca386d65ea7043aaac40302325d0dc7391a73b585571e28d3287d6b162033bb13029ce7b1f559ef5e747fcac439f1455a2ec7c5f09b72290795e70665044ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a010000001976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac3075000000000000ffffffff900a6c6ff6cd938bf863e50613a4ed5fb1661b78649fe354116edaf5d4abb9520000000001000000";

    let test_tx = Tx {
        version: 2,
        inputs: vector[
            Input {
                tx_id: x"ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a",
                vout: 1,
                script_sig: vector[], //  empty for P2WPKH
                sequence: 0xffffffff,
            },
        ],
        outputs: vector[
            Output {
                value: 20000, // 0x4e20
                script_pub_key: x"76a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac",
            },
        ],
        lock_time: 0,
        witness: vector[],
    };

    let input_idx_being_signed = 0u64;
    let script_code_for_input = x"76a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    let amount_spent_by_this_input = 30000u64;
    let sighash_type_byte = SIGHASH_ALL; // 0x01

    let result_preimage = create_bip143_sighash_preimage(
        &test_tx,
        input_idx_being_signed,
        &script_code_for_input,
        amount_spent_by_this_input,
        sighash_type_byte,
    );

    assert_eq!(result_preimage, expected_preimage);
}
