module btc_execution::tx_execution;
use btc_execution::interpreter::run;


public struct Input has copy, drop {
    data: vector<u8>
}

public struct Tx has copy, drop {
    inputs: vector<Input>
}

public fun executeTX(tx: Tx) : bool {
    let mut i = 0;
    while (i < tx.inputs.length()) {
        if (run(tx.inputs[i].data) == false) {
            return false
        };
        i = i + 1;
    };
    return true
}
