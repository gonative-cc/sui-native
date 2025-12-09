// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::interpreter;

use bitcoin_executor::stack::{Self, Stack};
use bitcoin_lib::crypto::hash256;
use bitcoin_lib::encoding::{
    u64_to_le_bytes,
    vector_false,
    vector_true,
    u64_to_cscriptnum,
    zerohash_32bytes,
    script_to_var_bytes,
    parse_btc_sig
};
use bitcoin_lib::input;
use bitcoin_lib::opcode;
use bitcoin_lib::output;
use bitcoin_lib::reader::{Self, Reader};
use bitcoin_lib::ripemd160;
use bitcoin_lib::sighash::{Self, create_p2wpkh_scriptcode};
use bitcoin_lib::tx::{Self, Transaction};
use std::hash::sha2_256;

#[test_only]
use std::unit_test::assert_eq;
// Opcodes are now defined in bitcoin_lib::opcode module

// Constants for interpreter operation results
const SUCCESS: u64 = 0;

// Signature and hash types
const SIG_VERSION_BASE: u8 = 0;
const SIG_VERSION_WITNESS_V0: u8 = 1; //SEGWIT
const SHA256: u8 = 1;

// ============= Errors ================================
#[error]
const EEqualVerify: vector<u8> = b"SCRIPT_ERR_EQUALVERIFY";
#[error]
const EUnsupportedSigVersionForChecksig: vector<u8> =
    b"Unsupported signature version for op_checksig";
#[error]
const EInvalidPKHLength: vector<u8> = b"PHK length must be 20";

const EPopStackEmpty: u64 = 1;
const ETopStackEmpty: u64 = 2;
const EMissingTxCtx: u64 = 3;
const EInvalidOpcode: u64 = 4;
const EInternalBitcoinCoreOpcode: u64 = 5;

public struct EvalResult has copy, drop {
    res: bool,
    err: u64,
}

public fun is_success(res: &EvalResult): bool {
    return res.err == 0 && res.res
}

public fun error(res: &EvalResult): u64 {
    res.err
}

public struct TransactionContext has copy, drop {
    tx: Transaction,
    // we use u64 for query vector index in sui move easier.
    input_index: u64,
    amount: u64,
    sig_version: u8, //TODO: maybe enum for it?
}

public struct Interpreter has copy, drop {
    stack: Stack,
    reader: Reader,
    tx_context: Option<TransactionContext>,
}

public fun new_tx_context(
    tx: Transaction,
    input_index: u64,
    amount: u64,
    sig_version: u8,
): TransactionContext {
    TransactionContext {
        tx,
        input_index,
        amount,
        sig_version,
    }
}

public fun new_ip_with_context(stack: Stack, tx_ctx: TransactionContext): Interpreter {
    Interpreter {
        stack: stack,
        reader: reader::new(vector[]),
        tx_context: option::some(tx_ctx),
    }
}

/// Execute btc script
public fun run(
    tx: Transaction,
    stack: Stack,
    script: vector<u8>,
    input_idx: u64,
    amount: u64,
): EvalResult {
    let sig_version = if (tx.is_witness()) {
        SIG_VERSION_WITNESS_V0
    } else {
        SIG_VERSION_BASE
    };

    let ctx = new_tx_context(
        tx,
        input_idx as u64,
        amount,
        sig_version,
    );

    let mut ip = new_ip_with_context(stack, ctx);
    let r = reader::new(script);
    ip.eval(r)
}

fun eval(ip: &mut Interpreter, r: Reader): EvalResult {
    ip.reader = r; // init new  reader
    while (!ip.reader.end_stream()) {
        let op = ip.reader.next_opcode();

        let err = if (op == opcode::OP_0!()) {
            ip.op_push_empty_vector()
        } else if (op >= opcode::OP_PUSHBYTES_1!() && op <= opcode::OP_PUSHBYTES_75!()) {
            ip.op_push_n_bytes(op)
        } else if (op >= opcode::OP_1!() && op <= opcode::OP_16!()) {
            ip.op_push_small_int(op)
        } else if (op == opcode::OP_DUP!()) {
            ip.op_dup()
        } else if (op == opcode::OP_DROP!()) {
            ip.op_drop()
        } else if (op == opcode::OP_SWAP!()) {
            ip.op_swap()
        } else if (op == opcode::OP_SIZE!()) {
            ip.op_size()
        } else if (op == opcode::OP_EQUAL!()) {
            ip.op_equal()
        } else if (op == opcode::OP_EQUALVERIFY!()) {
            ip.op_equal_verify()
        } else if (op == opcode::OP_SHA256!()) {
            ip.op_sha256()
        } else if (op == opcode::OP_HASH256!()) {
            ip.op_hash256()
        } else if (op == opcode::OP_CHECKSIG!()) {
            ip.op_checksig()
        } else if (op == opcode::OP_HASH160!()) {
            ip.op_hash160()
        } else if (isBitcoinCoreInternalOpCode(op)) {
            // Bitcoin Core internal use opcode.  Defined here for completeness.
            // https://github.com/btcsuite/btcd/blob/v0.24.2/txscript/opcode.go#L581
            EInternalBitcoinCoreOpcode
        } else {
            // isInvalidOptCode
            EInvalidOpcode
        };

        if (err != 0) {
            return EvalResult {
                res: false,
                err,
            }
        };
    };
    EvalResult {
        res: ip.isSuccess(),
        err: 0,
    }
}

fun isInvalidOptCode(op: u8): bool {
    op == opcode::OP_INVALIDOPCODE!() ||
        op >= opcode::OP_UNKNOWN187!() && op <= opcode::OP_UNKNOWN249!()
}

fun isBitcoinCoreInternalOpCode(op: u8): bool {
    op == opcode::OP_UNKNOWN252!() || op == opcode::OP_SMALLINTEGER!() ||
        op == opcode::OP_PUBKEY!() || op == opcode::OP_PUBKEYS!() || op == opcode::OP_PUBKEYHASH!()
}

/// check evaluate is valid
/// evaluation valid if the stack not empty
/// and top element is non zero value
public fun isSuccess(ip: &Interpreter): bool {
    if (ip.stack.is_empty()) {
        return false
    };
    let top = ip.stack.top();
    cast_to_bool(&top.destroy_or!(abort ETopStackEmpty))
}

fun cast_to_bool(v: &vector<u8>): bool {
    let mut i = 0;
    while (i < v.length()) {
        if (v[i] != 0) {
            // Can be negative zero
            if (i == v.length()-1 && v[i] == 0x80) return false;
            return true;
        };
        i = i + 1;
    };
    false
}

fun op_push_empty_vector(ip: &mut Interpreter): u64 {
    ip.stack.push(vector[]);
    SUCCESS
}

fun op_push_n_bytes(ip: &mut Interpreter, num_bytes_to_push: u8): u64 {
    let data_to_push = ip.reader.read(num_bytes_to_push as u64);
    ip.stack.push(data_to_push);
    SUCCESS
}

fun op_push_small_int(ip: &mut Interpreter, opcode: u8): u64 {
    // OP_1 (81) corresponds to 1  (81 - 81 + 1 = 1)
    // OP_16 (96) corresponds to 16 (96 - 81 + 1 = 16)
    let numeric_value: u8 = opcode - opcode::OP_1!() + 1;
    ip.stack.push_byte(numeric_value);
    SUCCESS
}

fun op_equal(ip: &mut Interpreter): u64 {
    let first_value = ip.stack.pop();
    let second_value = ip.stack.pop();

    if (first_value.is_none() || second_value.is_none()) {
        return EPopStackEmpty
    };
    let ans = if (first_value == second_value) {
        vector[1]
    } else {
        vector[0]
    };
    ip.stack.push(ans);
    SUCCESS
}

fun op_equal_verify(ip: &mut Interpreter): u64 {
    let previous_opcode_result = ip.op_equal();
    if (previous_opcode_result != SUCCESS) {
        return previous_opcode_result
    };
    let is_equal = ip.stack.pop().destroy_or!(abort EPopStackEmpty);
    assert!(is_equal == vector[1], EEqualVerify);
    SUCCESS
}

// OP_DUP eval
fun op_dup(ip: &mut Interpreter): u64 {
    let mut value = ip.stack.top();
    if (value.is_none()) {
        EPopStackEmpty
    } else {
        ip.stack.push(value.extract());
        SUCCESS
    }
}

fun op_drop(ip: &mut Interpreter): u64 {
    if (ip.stack.is_empty()) {
        return EPopStackEmpty
    };
    ip.stack.pop();
    SUCCESS
}

fun op_size(ip: &mut Interpreter): u64 {
    let mut top_element = ip.stack.top();
    if (top_element.is_none()) {
        return ETopStackEmpty
    };
    let size = top_element.extract().length();
    ip.stack.push(u64_to_cscriptnum(size));
    SUCCESS
}

fun op_swap(ip: &mut Interpreter): u64 {
    let mut first_element = ip.stack.pop();
    let mut second_element = ip.stack.pop();
    if (first_element.is_none() || second_element.is_none()) {
        return EPopStackEmpty
    };
    ip.stack.push(first_element.extract());
    ip.stack.push(second_element.extract());
    SUCCESS
}

fun op_sha256(ip: &mut Interpreter): u64 {
    let mut value = ip.stack.pop();
    if (value.is_none()) {
        return EPopStackEmpty
    };
    ip.stack.push(sha2_256(value.extract()));
    SUCCESS
}

fun op_hash256(ip: &mut Interpreter): u64 {
    let mut value = ip.stack.pop();
    if (value.is_none()) {
        return EPopStackEmpty
    };
    ip.stack.push(hash256(value.extract()));
    SUCCESS
}

fun op_checksig(ip: &mut Interpreter): u64 {
    let mut pubkey_bytes = ip.stack.pop();
    if (pubkey_bytes.is_none()) {
        return EPopStackEmpty
    };

    let mut sig_bytes = ip.stack.pop();
    if (sig_bytes.is_none()) {
        return EPopStackEmpty
    };

    let pubkey_bytes = pubkey_bytes.extract();
    let mut sig_bytes = sig_bytes.extract();

    if (sig_bytes.is_empty()) {
        ip.stack.push(vector_false());
        return SUCCESS
    };

    // https://learnmeabitcoin.com/technical/keys/signature/
    let (sig_to_verify, sighash_flag) = parse_btc_sig(&mut sig_bytes);

    if (option::is_none(&ip.tx_context)) { return EMissingTxCtx };

    let message_digest = create_sighash(ip, pubkey_bytes, sighash_flag);

    let signature_is_valid = sui::ecdsa_k1::secp256k1_verify(
        &sig_to_verify,
        &pubkey_bytes,
        &message_digest,
        SHA256,
    );

    if (signature_is_valid) {
        ip.stack.push(vector_true());
    } else {
        ip.stack.push(vector_false());
    };
    SUCCESS
}

fun create_sighash(ip: &Interpreter, pub_key: vector<u8>, sighash_flag: u8): vector<u8> {
    let ctx = ip.tx_context.borrow();
    if (ctx.sig_version == SIG_VERSION_WITNESS_V0) {
        let sha = sha2_256(pub_key);
        let mut hash160 = ripemd160::new();
        hash160.write(sha, sha.length());
        let pkh = hash160.finalize();
        let script_code_to_use_for_sighash = create_p2wpkh_scriptcode(pkh);

        let bip143_preimage = sighash::create_segwit_preimage(
            &ctx.tx,
            ctx.input_index,
            &script_code_to_use_for_sighash,
            u64_to_le_bytes(ctx.amount),
            sighash_flag,
        );
        // sui::ecdsa_k1::secp256k1_verify does the 2nd hash. We need to do the first here
        sha2_256(bip143_preimage)
    } else {
        abort EUnsupportedSigVersionForChecksig
    }
}

fun op_hash160(ip: &mut Interpreter): u64 {
    let value = ip.stack.pop().destroy_or!(abort EPopStackEmpty);
    let sha = sha2_256(value);
    let mut hasher = ripemd160::new();
    hasher.write(sha, sha.length());
    ip.stack.push(hasher.finalize());
    SUCCESS
}

#[test]
fun test_op_0() {
    let mut ip = new_empty_test_ip();
    ip.op_push_empty_vector();

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top().destroy_or!(abort);
    assert_eq!(top_val, vector[]);
    assert_eq!(ip.isSuccess(), false);
}

#[test]
fun test_op_push_n_bytes() {
    let mut ip = new_empty_test_ip();
    let script = vector[0x01, 0x02, 0x03, 0x04, 0x05, 0x06];
    let reader = reader::new(script);
    ip.reader = reader;

    let num_bytes: u8 = 3;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 1);
    let top_val = ip.stack.top().destroy_some();
    assert_eq!(top_val, vector[0x01, 0x02, 0x03]);
    assert_eq!(ip.isSuccess(), true);

    let num_bytes: u8 = 1;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 2);
    let top_val = ip.stack.top().destroy_some();
    assert_eq!(top_val, vector[0x04]);
    assert_eq!(ip.isSuccess(), true);

    let num_bytes: u8 = 2;
    ip.op_push_n_bytes(num_bytes);

    assert_eq!(ip.stack.size(), 3);
    let top_val = ip.stack.top().destroy_some();
    assert_eq!(top_val, vector[0x05, 0x06]);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_push_small_int() {
    let mut ip = new_empty_test_ip();

    ip.op_push_small_int_helper(opcode::OP_1!(), 1, vector[0x01]);
    ip.op_push_small_int_helper(opcode::OP_1!()+6, 2, vector[0x07]);
    ip.op_push_small_int_helper(opcode::OP_16!(), 3, vector[0x10]);
}

#[test]
fun test_op_push_small_int5() {
    let mut ip = new_empty_test_ip();
    ip.op_push_small_int_helper(opcode::OP_1!()+4, 1, vector[0x05]);
}

#[test_only]
fun op_push_small_int_helper(
    ip: &mut Interpreter,
    opcode: u8,
    expected_size: u64,
    top_val: vector<u8>,
) {
    ip.op_push_small_int(opcode);
    assert_eq!(ip.stack.size(), expected_size);
    assert_eq!(ip.stack.top().destroy_some(), top_val);
    assert_eq!(ip.isSuccess(), true);
}

#[test]
fun test_op_equal() {
    let mut ip = new_test_ip(vector[vector[10], vector[10]]);
    ip.op_equal();
    assert_eq!(ip.stack.top().destroy_or!(abort), vector[1]);

    ip.stack.push(vector[1]);
    ip.op_equal();
    assert_eq!(ip.stack.top().destroy_or!(abort), vector[1]);

    ip.stack.push(vector[20]);
    ip.stack.push(vector[10]);
    ip.op_equal();
    assert_eq!(ip.stack.top().destroy_or!(abort), vector[0]);
}

#[test]
fun test_op_equal_verify() {
    let mut ip = new_test_ip(vector[vector[10], vector[10]]);
    ip.op_equal_verify();
}

#[test, expected_failure(abort_code = EEqualVerify)]
fun test_op_equal_verify_fail() {
    let mut ip = new_test_ip(vector[vector[10], vector[12]]);
    ip.op_equal_verify();
}

#[test]
fun test_op_equal_fail() {
    let mut ip = new_test_ip(vector[vector[10]]);
    ip.op_equal();
}

#[test]
fun test_op_dup() {
    let mut ip = new_test_ip(vector[vector[10]]);
    ip.op_dup();
    assert_eq!(ip.stack.get_all_values(), vector[vector[10], vector[10]]);
    assert_eq!(ip.stack.size(), 2);
}

#[test]
fun test_op_dup_fail() {
    let mut ip = new_empty_test_ip();
    ip.op_dup();
}

#[test]
fun test_op_drop() {
    let mut ip = new_test_ip(vector[vector[1]]);
    ip.op_drop();
    assert_eq!(ip.stack.get_all_values(), vector[]);
    assert_eq!(ip.stack.size(), 0);
}

#[test]
fun test_op_drop_fail() {
    let mut ip = new_empty_test_ip();
    assert_eq!(ip.op_drop(), EPopStackEmpty);
}

#[test]
fun test_op_swap() {
    let mut ip = new_test_ip(vector[vector[1], vector[2]]);
    ip.op_swap();
    assert_eq!(ip.stack.size(), 2);
    assert_eq!(ip.stack.get_all_values(), vector[vector[0x02], vector[0x01]]);
}

#[test]
fun test_op_swap_fail() {
    let mut ip = new_test_ip(vector[vector[1]]);
    assert_eq!(ip.op_swap(), EPopStackEmpty);
}

#[test]
fun test_op_size() {
    let mut ip = new_test_ip(vector[vector[1], vector[1, 2, 3, 8]]); // top element size = 4
    ip.op_size();
    assert_eq!(ip.stack.size(), 3);
    assert_eq!(
        ip.stack.get_all_values(),
        vector[vector[0x01], vector[0x01, 0x02, 0x03, 0x08], vector[0x04]],
    );
    assert_eq!(ip.stack.top().destroy_some(), vector[0x04]);
}

#[test]
fun test_op_size_fail() {
    let mut ip = new_empty_test_ip();
    assert_eq!(ip.op_size(), ETopStackEmpty);
}

#[test]
fun test_op_sha256() {
    let mut ip = new_test_ip(vector[vector[0x01]]);
    ip.op_sha256();
    assert_eq!(ip.stack.size(), 1);
    let expected_hash: vector<u8> =
        x"4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a";
    assert_eq!(ip.stack.top().destroy_some(), expected_hash);
    assert_eq!(ip.stack.get_all_values(), vector[expected_hash]);
}

#[test]
fun test_op_hash256() {
    let mut ip = new_test_ip(vector[vector[0x01]]);
    ip.op_hash256();
    assert_eq!(ip.stack.size(), 1);
    let expected_hash: vector<u8> =
        x"9c12cfdc04c74584d787ac3d23772132c18524bc7ab28dec4219b8fc5b425f70";
    assert_eq!(ip.stack.top().destroy_some(), expected_hash);
    assert_eq!(ip.stack.get_all_values(), vector[expected_hash]);
}

#[test]
fun test_op_checksig() {
    // all the data for the test copied from the exmaple https://learnmeabitcoin.com/technical/keys/signature/
    //preimage = 02000000cbfaca386d65ea7043aaac40302325d0dc7391a73b585571e28d3287d6b162033bb13029ce7b1f559ef5e747fcac439f1455a2ec7c5f09b72290795e70665044ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a010000001976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac3075000000000000ffffffff900a6c6ff6cd938bf863e50613a4ed5fb1661b78649fe354116edaf5d4abb9520000000001000000
    //preimage_hashed256 = d7b60220e1b9b2c1ab40845118baf515203f7b6f0ad83cbb68d3c89b5b3098a6
    let signature_der_encoded =
        x"3044022008f4f37e2d8f74e18c1b8fde2374d5f28402fb8ab7fd1cc5b786aa40851a70cb022032b1374d1a0f125eae4f69d1bc0b7f896c964cfdba329f38a952426cf427484c01";
    let public_key = x"03eed0d937090cae6ffde917de8a80dc6156e30b13edd5e51e2e50d52428da1c87";

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

    let input_idx_being_signed = 0;
    let amount_spent_by_this_input = 30000u64;

    let tx_context = new_tx_context(
        test_tx,
        input_idx_being_signed,
        amount_spent_by_this_input,
        SIG_VERSION_WITNESS_V0,
    );
    let stack = stack::new();
    let mut ip = new_ip_with_context(stack, tx_context);

    ip.stack.push(signature_der_encoded);
    ip.stack.push(public_key);
    ip.op_checksig();

    assert_eq!(ip.stack.size(), 1);
    assert_eq!(ip.stack.top().destroy_some(), vector_true());
}

#[test]
fun test_op_hash160() {
    let mut ip = new_test_ip(vector[x"12345678"]);
    ip.op_hash160();
    assert_eq!(ip.stack.size(), 1);
    let expected_hash: vector<u8> = x"82c12e3c770a95bd17fd1d983d6b2af2037b7a4b";
    assert_eq!(ip.stack.top().destroy_some(), expected_hash);
    assert_eq!(ip.stack.get_all_values(), vector[expected_hash]);
}

#[test]
fun test_op_unknown252() {
    assert_eq!(
        eval_test_ip(vector[opcode::OP_UNKNOWN252!()], vector[]).err,
        EInternalBitcoinCoreOpcode,
    );
}

#[test]
fun test_op_smallinteger() {
    assert_eq!(
        eval_test_ip(vector[opcode::OP_SMALLINTEGER!()], vector[]).err,
        EInternalBitcoinCoreOpcode,
    );
}

#[test]
fun test_op_pubkey() {
    assert_eq!(
        eval_test_ip(vector[opcode::OP_PUBKEY!()], vector[]).err,
        EInternalBitcoinCoreOpcode,
    );
}

#[test]
fun test_op_pubkeys() {
    assert_eq!(
        eval_test_ip(vector[opcode::OP_PUBKEYS!()], vector[]).err,
        EInternalBitcoinCoreOpcode,
    );
}

#[test]
fun test_op_pubkhash() {
    assert_eq!(
        eval_test_ip(vector[opcode::OP_PUBKEYHASH!()], vector[]).err,
        EInternalBitcoinCoreOpcode,
    );
}

#[test]
fun test_op_invalid() {
    assert_eq!(eval_test_ip(vector[opcode::OP_INVALIDOPCODE!()], vector[]).err, EInvalidOpcode);
}

#[test]
fun test_op_unknown187() {
    assert_eq!(eval_test_ip(vector[opcode::OP_UNKNOWN187!()], vector[]).err, EInvalidOpcode);
}

#[test]
fun test_op_unknown249() {
    assert_eq!(eval_test_ip(vector[opcode::OP_UNKNOWN249!()], vector[]).err, EInvalidOpcode);
}

#[test]
fun test_op_unknown188() {
    assert_eq!(eval_test_ip(vector[opcode::OP_UNKNOWN187!()+1], vector[]).err, EInvalidOpcode);
}

#[test_only]
fun eval_test_ip(script: vector<u8>, stack_data: vector<vector<u8>>): EvalResult {
    let mut ip = new_test_ip(stack_data);
    ip.eval(reader::new(script))
}

#[test_only]
fun new_empty_test_ip(): Interpreter {
    new_test_ip(vector[])
}

#[test_only]
fun new_test_ip(stack_data: vector<vector<u8>>): Interpreter {
    let stack = stack::new_with_data(stack_data);
    Interpreter {
        stack: stack,
        reader: reader::new(vector[]),
        tx_context: option::none(),
    }
}
