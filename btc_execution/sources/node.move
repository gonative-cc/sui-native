/// Module: btc_execution
module btc_execution::btc_execution;
use btc_execution::tx::{Tx, Self};


fun init(_ctx: &mut tx_context::TxContext) {
}


/// A block is a collection of all transactions in the BTC block
public struct Block has copy, drop {
    txns: vector<Tx>
}

/// State store all valid BTC blocks
public struct State has key, store {
    id: UID
}

fun store(_state: &mut State, _block: &Block) {
    // TODO: Implement this.
}

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
