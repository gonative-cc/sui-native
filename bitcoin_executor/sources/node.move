// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::bitcoin_executor;

use bitcoin_executor::block;
use bitcoin_executor::interpreter::{run, create_p2wpkh_scriptcode};
use bitcoin_executor::stack;
use bitcoin_executor::tx::Transaction;
use bitcoin_executor::utils::LEtoNumber;
use bitcoin_executor::utxo::{Self, OutPoint, Data};
use sui::table::{Self, Table};

#[test_only]
use std::unit_test::assert_eq;

#[error]
const ECoinbaseNotMature: vector<u8> =
    b"Coinbase tx is not spendable until it reaches maturity of 100 blocks";
#[error]
const EInvalidTransaction: vector<u8> = b"Invalid transaction";
#[error]
const EInvalidCoinbase: vector<u8> = b"Invalid coinbase transaction";
#[error]
const EBlockEmpty: vector<u8> = b"Block cannot empty";
#[error]
const EUTXOInvalid: vector<u8> = b"UTXO already spend";

fun init(ctx: &mut TxContext) {
    let state = State {
        id: object::new(ctx),
        utxos: table::new<OutPoint, Data>(ctx),
        height: 0,
    };
    transfer::share_object(state);
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

        let (outpoint, data) = utxo::new(
            tx.tx_id(),
            index as u32,
            state.height,
            coinbase,
            LEtoNumber(output.amount()),
            output.script_pubkey(),
        );
        state.add_utxo(outpoint, data);
    })
}

fun spend(s: &mut State, tx: &Transaction) {
    tx.inputs().do!(|input| {
        let outpoint = utxo::new_outpoint(
            input.tx_id(),
            LEtoNumber(input.vout()) as u32,
        );

        let height = s.height;
        s.spend_utxo(outpoint, height);
    });
}

public fun execute_block(state: &mut State, raw_block: vector<u8>) {
    let block = block::new(raw_block);
    assert!(!block.txns().is_empty(), EBlockEmpty); // block should be empty
    assert!(block.txns()[0].is_coinbase(), EInvalidCoinbase);
    // TODO: handle case tx_id is identical for coinbase
    state.store(&block.txns()[0], true);
    let mut i = 1;
    while (i < block.txns().length()) {
        let txn = block.txns()[i];
        assert!(validate_execution(state, txn), EInvalidTransaction);
        state.store(&txn, false);
        state.spend(&txn);
        i = i + 1;
    };

    state.height = state.height + 1;
}

fun validate_execution(state: &State, tx: Transaction): bool {
    let number_input = tx.inputs().length();
    let mut i = 0;
    let mut result = true;
    while (i < number_input) {
        let stack = stack::new_with_data(tx.witness()[i].items());
        let outpoint = utxo::new_outpoint(
            tx.input_at(i).tx_id(),
            LEtoNumber(tx.input_at(i).vout()) as u32,
        );

        let utxo_valid = state.utxo_exists(outpoint);
        assert!(utxo_valid, EUTXOInvalid);

        let data = state.utxos.borrow(outpoint);

        // TODO: We only support P2WPKH now.
        // We will support more standard scripts.
        let pk = data.pkh();
        let script = create_p2wpkh_scriptcode(pk);
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
        height: 0,
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
        height: 0,
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
        height: 0,
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
        height: 0,
    };
    add_utxo(&mut state, outpint, info);
    spend_utxo(&mut state, outpint, 101);
    transfer::public_transfer(state, @0xCAFE);
}

#[test]
fun execution_node_test() {
    let mut ctx = tx_context::dummy();

    let (outpint, info) = utxo::new(
        x"d2515c87b7afba3a576e80af3727b7511025a9615db33a3a768415601aeb59c1",
        0,
        0,
        true,
        5000000000,
        x"001460bef4984dfcc473d6459368f4f1f9a21d1f4d74",
    );

    let mut state = State {
        id: object::new(&mut ctx),
        utxos: table::new<OutPoint, Data>(&mut ctx),
        height: 100,
    };
    add_utxo(&mut state, outpint, info);

    let b =
        x"000000304bdcc0c79dd25f7015d31f18378809194952ba3f48e24740296483ed8275c24363c09db423bc6561e301f2a15072ed9f486cad532f224ad001413328f50f81b546f53968ffff7f200100000002020000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff0402c90000ffffffff0282fe02950000000016001460bef4984dfcc473d6459368f4f1f9a21d1f4d740000000000000000266a24aa21a9ed6f83cd98869e89b7a7546b79cb2c6fec9237747c61971f9559290b3d346e7ba1012000000000000000000000000000000000000000000000000000000000000000000000000002000000000101d2515c87b7afba3a576e80af3727b7511025a9615db33a3a768415601aeb59c10000000000fdffffff027e0b102401000000160014bd528c78cca2d4061db49ba4027985e916aa95d300e1f505000000001600142ad63da1511b7cc438e5a121c4f502afd949504f024730440220532f7dcdd9202fc9a5bf3e119bd2169aaec58a86565588325bedfa34b85474ef02206068659530ef8a92316d26cfd2f7dbc9a05892c17d07ea3b6108687b7cec8e4d012103ff593f331f3ec8d418b466610281acdbadbfda2e24c5592b3120940f3aed94bcc8000000";

    state.execute_block(b);

    // let b = block::new(b);
    // std::debug::print(&b);
    // b.txns().do!(|txn| {
    //     txn.outputs().length().do!(|idx| {
    //         let o = utxo::new_outpoint(txn.tx_id(), idx as u32);
    //         assert!(state.utxo_exists(o));
    //         std::debug::print(state.utxos.borrow(o));
    //     })
    // });

    transfer::public_transfer(state, @0xCAFE);
}

#[test, expected_failure(abort_code = EUTXOInvalid)]
fun execution_node_double_spend_test() {
    let mut ctx = tx_context::dummy();

    let (outpint, info) = utxo::new(
        x"d2515c87b7afba3a576e80af3727b7511025a9615db33a3a768415601aeb59c1",
        0,
        0,
        true,
        5000000000,
        x"001460bef4984dfcc473d6459368f4f1f9a21d1f4d74",
    );

    let mut state = State {
        id: object::new(&mut ctx),
        utxos: table::new<OutPoint, Data>(&mut ctx),
        height: 100,
    };
    add_utxo(&mut state, outpint, info);

    let b =
        x"000000304bdcc0c79dd25f7015d31f18378809194952ba3f48e24740296483ed8275c24363c09db423bc6561e301f2a15072ed9f486cad532f224ad001413328f50f81b546f53968ffff7f200100000002030000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff0402c90000ffffffff0282fe02950000000016001460bef4984dfcc473d6459368f4f1f9a21d1f4d740000000000000000266a24aa21a9ed6f83cd98869e89b7a7546b79cb2c6fec9237747c61971f9559290b3d346e7ba1012000000000000000000000000000000000000000000000000000000000000000000000000002000000000101d2515c87b7afba3a576e80af3727b7511025a9615db33a3a768415601aeb59c10000000000fdffffff027e0b102401000000160014bd528c78cca2d4061db49ba4027985e916aa95d300e1f505000000001600142ad63da1511b7cc438e5a121c4f502afd949504f024730440220532f7dcdd9202fc9a5bf3e119bd2169aaec58a86565588325bedfa34b85474ef02206068659530ef8a92316d26cfd2f7dbc9a05892c17d07ea3b6108687b7cec8e4d012103ff593f331f3ec8d418b466610281acdbadbfda2e24c5592b3120940f3aed94bcc8000000";

    state.execute_block(b);

    let b =
        x"000000304bdcc0c79dd25f7015d31f18378809194952ba3f48e24740296483ed8275c24363c09db423bc6561e301f2a15072ed9f486cad532f224ad001413328f50f81b546f53968ffff7f200100000002040000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff0402c90000ffffffff0282fe02950000000016001460bef4984dfcc473d6459368f4f1f9a21d1f4d740000000000000000266a24aa21a9ed6f83cd98869e89b7a7546b79cb2c6fec9237747c61971f9559290b3d346e7ba1012000000000000000000000000000000000000000000000000000000000000000000000000002000000000101d2515c87b7afba3a576e80af3727b7511025a9615db33a3a768415601aeb59c10000000000fdffffff027e0b102401000000160014bd528c78cca2d4061db49ba4027985e916aa95d300e1f505000000001600142ad63da1511b7cc438e5a121c4f502afd949504f024730440220532f7dcdd9202fc9a5bf3e119bd2169aaec58a86565588325bedfa34b85474ef02206068659530ef8a92316d26cfd2f7dbc9a05892c17d07ea3b6108687b7cec8e4d012103ff593f331f3ec8d418b466610281acdbadbfda2e24c5592b3120940f3aed94bcc8000000";

    state.execute_block(b);
    abort
}
