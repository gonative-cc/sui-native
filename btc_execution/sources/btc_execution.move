/// Module: btc_execution
module btc_execution::btc_execution;


fun init(_ctx: &mut tx_context::TxContext) {
}


public struct Block has copy, drop{
}


public fun executeBlock(_block: &Block): bool {
    return true
}
