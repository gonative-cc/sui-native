/// Module: btc_execution
module btc_execution::btc_execution;
use btc_execution::tx_execution::{Tx, executeTX};


fun init(_ctx: &mut tx_context::TxContext) {
}


public struct Block has copy, drop {
    txns: vector<Tx>
}

public struct State has key, store {
    id: UID
}

fun store(_state: &mut State, _block: &Block) {

}

public fun executeBlock(state: &mut State, block: &Block): bool {
    let mut i = 0;
    while (i < block.txns.length()) {
        if (executeTX(block.txns[i]) == false) {
            return false
        };
        i = i + 1;
    };

    state.store(block);
    return true
}
