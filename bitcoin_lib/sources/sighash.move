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
const EInvalidPKHLength: vector<u8> = b"PKH length must be 20";
#[error]
const EPreviousPubScriptLengthMismach: vector<u8> =
    b"Previous pubscripts length mismatch with inputs length";
#[error]
const EValuesLengthMismatch: vector<u8> = b"size of values mismatch with inputs length";

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

/// Compute sighash of taproot transaction
/// tx: The taproot tx
/// input_idx_to_sign: the input id we want to sign
/// previous_pubscripts: the previous pubscripts of all inputs
/// values: the values in utxos we want to spend
/// leaf_hash: leaf hash of script we want to spend,  for spend utxo by key path this is none
/// annex: a reserved space for future upgrades. BTC doesn't use this yet
public fun taproot_sighash(
    tx: &Transaction,
    input_idx_to_sign: u32,
    previous_pubscripts: vector<vector<u8>>,
    values: vector<u64>,
    hash_type: u8,
    leaf_hash: Option<vector<u8>>, // for spend utxo by key path this is none
    annex: Option<vector<u8>>, // BTC don't active this yet!
): vector<u8> {
    assert!(previous_pubscripts.length() == tx.inputs().length(), EPreviousPubScriptLengthMismach);
    assert!(values.length() == tx.inputs().length(), EValuesLengthMismatch);
    //follow https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#common-signature-message
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
            hash_script_pubkeys.append(script_to_var_bytes(&pub_scripts))
        });
        hash_script_pubkeys = sha256(hash_script_pubkeys);
    };
    if ((is_none || is_single) == false) {
        tx.outputs().do!(|output| {
            hash_outputs.append(output.amount_bytes());
            hash_outputs.append(script_to_var_bytes(&output.script_pubkey()));
        });
        hash_outputs = sha256(hash_outputs);
    } else if (is_single && (input_idx_to_sign as u64 < tx.outputs().length())) {
        let output = tx.output_at(input_idx_to_sign as u64);
        hash_outputs.append(output.amount_bytes());
        hash_outputs.append(script_to_var_bytes(&output.script_pubkey()));
        hash_outputs = sha256(hash_outputs);
    } else if (is_single && (input_idx_to_sign as u64 >= tx.outputs().length())) {
        // BIP-341: SIGHASH_SINGLE with input index out of range.
        // hash_outputs intentionally left empty (no output hash included).
        // This matches the required behavior: the hash is still computed, but without any output hash.
    };

    let mut preimage = vector::empty();
    preimage.append(vector[hash_type]);
    preimage.append(tx.version());
    preimage.append(tx.locktime());
    preimage.append(hash_prevouts);
    preimage.append(hash_amounts);
    preimage.append(hash_script_pubkeys);
    preimage.append(hash_sequences);
    if ((is_none || is_single) == false) {
        preimage.append(hash_outputs);
    };
    let mut spend_type: u8 = if (leaf_hash.is_some()) 2 else 0;
    spend_type = spend_type + if (annex.is_some()) 1 else 0;
    preimage.push_back(spend_type);
    if (is_any_one_can_pay) {
        let inp = tx.input_at(input_idx_to_sign as u64);
        preimage.append(inp.tx_id());
        preimage.append(inp.vout());
        preimage.append(u64_to_le_bytes(values[input_idx_to_sign as u64]));
        preimage.append(
            script_to_var_bytes(&previous_pubscripts[input_idx_to_sign as u64]),
        );
        preimage.append(inp.sequence());
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
    // hash_tag(x) = SHA256(SHA256(tag) || SHA256(tag) || x)
    // in our case tag is "TapSighash"
    // https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#specification
    // duplicate sha256("TapSighash");
    let mut hash_data =
        x"f40a48df4b2a70c8b4924bf2654661ed3d95fd66a313eb87237597c628e4a031f40a48df4b2a70c8b4924bf2654661ed3d95fd66a313eb87237597c628e4a031";
    // Extra zero byte because:
    // https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#cite_note-20
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
fun test_taproot_sighash() {
    // data from https://github.com/bitcoinjs/bitcoinjs-lib/blob/13aea8c84236fe14d7260a9ffaaf0a0489ef70b1/test/fixtures/transaction.json#L812
    let mut r = bitcoin_lib::reader::new(
        x"02000000097de20cbff686da83a54981d2b9bab3586f4ca7e48f57f5b55963115f3b334e9c010000000000000000d7b7cab57b1393ace2d064f4d4a2cb8af6def61273e127517d44759b6dafdd990000000000fffffffff8e1f583384333689228c5d28eac13366be082dc57441760d957275419a418420000000000fffffffff0689180aa63b30cb162a73c6d2a38b7eeda2a83ece74310fda0843ad604853b0100000000feffffff0c638ca38362001f5e128a01ae2b379288eb22cfaf903652b2ec1c88588f487a0000000000feffffff956149bdc66faa968eb2be2d2faa29718acbfe3941215893a2a3446d32acd05000000000000000000081efa267f1f0e46e054ecec01773de7c844721e010c2db5d5864a6a6b53e013a010000000000000000a690669c3c4a62507d93609810c6de3f99d1a6e311fe39dd23683d695c07bdee0000000000ffffffff727ab5f877438496f8613ca84002ff38e8292f7bd11f0a9b9b83ebd16779669e0100000000ffffffff0200ca9a3b000000001976a91406afd46bcdfd22ef94ac122aa11f241244a37ecc88ac807840cb0000000020ac9a87f5594be208f8532db38cff670c450ed2fea8fcdefcc9a663f78bab962b0065cd1d",
    );

    let txn = tx::deserialize(&mut r);

    let previous_output_pubscripts = vector[
        x"512053a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343",
        x"5120147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3",
        x"76a914751e76e8199196d454941c45d1b3a323f1433bd688ac",
        x"5120e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e",
        x"512091b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605",
        x"00147dd65592d0ab2fe0d0257d571abf032cd9db93dc",
        x"512075169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831",
        x"51200f63ca2c7639b9bb4be0465cc0aa3ee78a0761ba5f5f7d6ff8eab340f09da561",
        x"5120053690babeabbb7850c32eead0acf8df990ced79f7a31e358fabf2658b4bc587",
    ];

    let values = vector[
        420000000,
        462000000,
        294000000,
        504000000,
        630000000,
        378000000,
        672000000,
        546000000,
        588000000,
    ];

    // vector of (input_idx_to_sign, hash_type)
    let test_case_inputs = vector[
        vector[0, 3],
        vector[1, 0x83],
        vector[3, 0x01],
        vector[4, 0x00],
        vector[6, 0x02],
        vector[7, 0x82],
        vector[8, 0x81],
    ];
    let test_case_outputs = vector[
        x"7e584883b084ace0469c6962a9a7d2a9060e1f3c218ab40d32c77651482122bc",
        x"325a644af47e8a5a2591cda0ab0723978537318f10e6a63d4eed783b96a71a4d",
        x"6ffd256e108685b41831385f57eebf2fca041bc6b5e607ea11b3e03d4cf9d9ba",
        x"9f90136737540ccc18707e1fd398ad222a1a7e4dd65cbfd22dbe4660191efa58",
        x"835c9ab6084ed9a8ae9b7cda21e0aa797aca3b76a54bd1e3c7db093f6c57e23f",
        x"df1cca638283c667084b8ffe6bf6e116cc5a53cf7ae1202c5fee45a9085f1ba5",
        x"30319859ca79ea1b7a9782e9daebc46e4ca4ca2bc04c9c53b2ec87fa83a526bd",
    ];

    test_case_inputs.length().do!(|i| {
        let input_idx_to_sign = test_case_inputs[i][0] as u32;
        let hash_type = test_case_inputs[i][1] as u8;
        let sighash = taproot_sighash(
            &txn,
            input_idx_to_sign,
            previous_output_pubscripts,
            values,
            hash_type,
            option::none(),
            option::none(),
        );
        assert_eq!(sighash, test_case_outputs[i]);
    });
}
// TODO: add a test case where user spends two UTXOs
//
