module bitcoin_executor::tx;
use bitcoin_executor::interpreter::run;


/// Input in btc transaction
public struct Input has copy, drop {
    tx_id: vector<u8>,
    vout: vector<u8>,
    script_sig: vector<u8>,
    sequence: vector<u8>
}

/// Output in btc transaction
public struct Output has copy, drop {
    amount: vector<u8>,
    script_pubkey: vector<u8>
}

/// BTC transaction
public struct Transaction has copy, drop {
    version: vector<u8>,
    inputs: vector<Input>,
    outputs: vector<Output>,
    witness: vector<u8>,
    locktime: vector<u8>
}


public fun new_transaction() : Transaction {
    Transaction {

    }
}
/// Validate BTC transaction
public fun execute(tx: Transaction) : bool {
    let mut i = 0;
    while (i < tx.inputs.length()) {
        if (run(tx.inputs[i].script_sig) == false) {
            return false
        };
        i = i + 1;
    };
    true
}
