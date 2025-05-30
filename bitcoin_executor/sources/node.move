/// Module: bitcoin_executor
module bitcoin_executor::bitcoin_executor;
use bitcoin_executor::tx::{Transaction, Self};
use bitcoin_executor::output::Output;
use bitcoin_executor::block::validate_execution;

fun init(_ctx: &mut tx_context::TxContext) {}

/// A block is a collection of all transactions in the BTC block
public struct Block has copy, drop {
    txns: vector<Transaction>
}

/// State stores all valid BTC blocks
public struct State has key, store {
    id: UID,
}


fun store(_state: &mut State, _block: &Block) {
    // TODO: Implement this.
}

fun utxo(): vector<Output> {
    vector[]
}
public fun executeBlock(state: &mut State, block: &Block): bool {
    assert!(block.txns.is_empty()); // block should be empty
    assert!(block.txns[0].is_coinbase());
    let mut i = 1;
    while (i < block.txns.length()) {
        if (validate_execution(block.txns[i], utxo()) == false) {
            return false
        };
        i = i + 1;
    };
    state.store(block);
    true
}
