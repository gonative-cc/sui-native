/// Module: bitcoin_executor
module bitcoin_executor::bitcoin_executor;

use bitcoin_executor::tx;
use bitcoin_executor::types::Tx;

fun init(_ctx: &mut tx_context::TxContext) {}

/// A block is a collection of all transactions in the BTC block
public struct Block has copy, drop {
    txns: vector<Tx>,
}

/// State store all valid BTC blocks
public struct State has key, store {
    id: UID,
}

fun store(_state: &mut State, _block: &Block) {}

public fun executeBlock(state: &mut State, block: &Block): bool {
    let mut i = 0;
    while (i < block.txns.length()) {
        if (tx::execute(block.txns[i]) == false) {
            return false
        };
        i = i + 1;
    };
    state.store(block);
    true
}
