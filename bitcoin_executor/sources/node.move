module bitcoin_executor::bitcoin_executor;
use bitcoin_executor::tx::{Transaction, Self};
use bitcoin_executor::interpreter::{run, create_p2wpkh_scriptcode_bytes};
use bitcoin_executor::stack;
use bitcoin_executor::utils::LEtoNumber;

use bitcoin_executor::utxo::{Self, OutPoint, Data};
use std::unit_test::assert_eq;
use sui::table::{Self, Table};

#[error]
const ECoinbaseNotMature: vector<u8> =
    b"Coinbase tx is not spendable until it reaches maturity of 100 blocks";

fun init(ctx: &mut TxContext) {
    let state = State {
        id: object::new(ctx),
        utxos: table::new<OutPoint, Data>(ctx),
        height: 0
    };
    transfer::share_object(state);
}

/// A block is a collection of all transactions in the BTC block
public struct Block has copy, drop {
    txns: vector<Transaction>,
}

/// State stores the utxo set
public struct State has key, store {
    id: UID,
    utxos: Table<OutPoint, Data>,
    height: u64,
}

fun store(state: &mut State, tx: &Transaction, coinbase: bool) {
    tx.outputs().length().do!(|index| {
        let output = tx.output_at(index);

        let (outpoint, data) = utxo::new(tx.tx_id(), index as u32, state.height, coinbase, LEtoNumber(output.amount()), output.script_pubkey());
        state.add_utxo(outpoint, data);
    })
}

// TODO: integrate it with the parser and update the utxo set
public fun executeBlock(state: &mut State, block: &Block) {
    assert!(block.txns.is_empty()); // block should be empty
    assert!(block.txns[0].is_coinbase());
    state.store(&block.txns[0], true);
    let mut i = 1;
    while (i < block.txns.length()) {
        assert!(validate_execution(state, block.txns[i]));
        state.store(&block.txns[i], false);
        i = i + 1;
    };
}

fun validate_execution(state: &State, tx: Transaction) : bool{
    let number_input = tx.inputs().length();
    let mut i = 0;
    let mut result = true;
    while (i < number_input) {
        let stack = stack::create_with_data(tx.witness()[i].items());
        let outpoint = utxo::new_outpoint(
            tx.input_at(i).tx_id(),
            LEtoNumber(tx.input_at(i).vout()) as u32
        );
        let data = state.utxos.borrow(outpoint);
        let pk = data.pkh();
        let script = create_p2wpkh_scriptcode_bytes(pk);
        let valid = run(tx, stack, script, i, data.value());
        if (!valid) {
            result = false;
            break
        };
        i = i + 1;
    };

    result
}
/// Adds a new UTXO to the set
public fun add_utxo(state: &mut State, outpoint: OutPoint, info: Data) {
    state.utxos.add(outpoint, info);
}

/// Spends a UTXO checks for existence and coinbase maturity, removes it, and returns its Info
public fun spend_utxo(state: &mut State, outpoint: OutPoint, current_block_height: u64): Data {
    let utxo_info = state.utxos.borrow(outpoint);

    if (utxo_info.is_coinbase()) {
        assert!(current_block_height >= utxo_info.height() + 100, ECoinbaseNotMature);
    };
    state.utxos.remove(outpoint)
}

/// Checks if a UTXO exists in the set
public fun utxo_exists(state: &State, outpoint: OutPoint): bool {
    state.utxos.contains(outpoint)
}

#[test]
fun test_add_utxo() {
    let mut ctx = tx_context::dummy();

    let (outpint, info) = utxo::new(x"01", 1, 1, true, 1, x"01");

    let mut state = State {
        id: object::new(&mut ctx),
        utxos: table::new<OutPoint, Data>(&mut ctx),
        height: 0,
    };
    add_utxo(&mut state, outpint, info);
    assert_eq!(state.utxos.length(), 1);
    assert_eq!(state.utxos.contains(outpint), true);
    transfer::public_transfer(state, @0xCAFE);
}

#[test, expected_failure(abort_code = sui::dynamic_field::EFieldAlreadyExists)]
fun test_add_utxo_fail() {
    let mut ctx = tx_context::dummy();

    let (outpint, info) = utxo::new(x"01", 1, 1, true, 1, x"01");

    let mut state = State {
        id: object::new(&mut ctx),
        utxos: table::new<OutPoint, Data>(&mut ctx),
        height: 0
    };
    add_utxo(&mut state, outpint, info);
    add_utxo(&mut state, outpint, info);
    transfer::public_transfer(state, @0xCAFE);
}

#[test]
fun test_spend_utxo() {
    let mut ctx = tx_context::dummy();

    let (outpint, info) = utxo::new(x"01", 1, 1, false, 1, x"01");

    let mut state = State {
        id: object::new(&mut ctx),
        utxos: table::new<OutPoint, Data>(&mut ctx),
        height: 0
    };
    add_utxo(&mut state, outpint, info);
    spend_utxo(&mut state, outpint, 2);
    assert_eq!(state.utxos.length(), 0);
    transfer::public_transfer(state, @0xCAFE);
}

#[test]
fun test_spend_utxo_is_coinbase() {
    let mut ctx = tx_context::dummy();

    let (outpint, info) = utxo::new(x"01", 1, 1, true, 1, x"01");

    let mut state = State {
        id: object::new(&mut ctx),
        utxos: table::new<OutPoint, Data>(&mut ctx),
        height: 0
    };
    add_utxo(&mut state, outpint, info);
    spend_utxo(&mut state, outpint, 101);
    assert_eq!(state.utxos.length(), 0);
    transfer::public_transfer(state, @0xCAFE);
}

#[test, expected_failure(abort_code = ECoinbaseNotMature)]
fun test_spend_utxo_is_coinbase_fail() {
    let mut ctx = tx_context::dummy();

    let (outpint, info) = utxo::new(x"01", 1, 100, true, 1, x"01");

    let mut state = State {
        id: object::new(&mut ctx),
        utxos: table::new<OutPoint, Data>(&mut ctx),
        height: 0
    };
    add_utxo(&mut state, outpint, info);
    spend_utxo(&mut state, outpint, 101);
    transfer::public_transfer(state, @0xCAFE);
}
