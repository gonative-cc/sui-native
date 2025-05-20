module btc_execution::tx;
use btc_execution::interpreter::run;


/// Inputs in btc transaction
public struct Input has copy, drop {
    data: vector<u8>
}

/// BTC transaction
public struct Tx has copy, drop {
    inputs: vector<Input>
}

/// Validate BTC transaction
public fun execute(tx: Tx) : bool {
    let mut i = 0;
    while (i < tx.inputs.length()) {

        if (run(&tx.inputs[i].data) == false) {
            return false
        };
        i = i + 1;
    };
    return true
}
