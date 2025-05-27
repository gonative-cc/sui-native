module bitcoin_executor::tx;

// use bitcoin_executor::interpreter::run;

/// Inputs in btc transaction
public struct Input has copy, drop {
    /// Reference to the output being spent.
    tx_id: vector<u8>,
    vout: u32,
    /// https://learnmeabitcoin.com/technical/transaction/input/scriptsig/
    script_sig: vector<u8>,
    /// tx version
    sequence: u32,
}

public struct Output has copy, drop {
    /// in satoshi
    value: u64,
    /// script that locks the output (scriptPubKey)
    /// https://learnmeabitcoin.com/technical/script/
    script_pub_key: vector<u8>,
}

/// BTC transaction
public struct Tx has copy, drop {
    version: u32,
    inputs: vector<Input>,
    outputs: vector<Output>,
    lock_time: u32,
    witness: vector<u8>,
}

/// Validate BTC transaction
public fun execute(tx: Tx): bool {
    let mut i = 0;
    while (i < tx.inputs.length()) {
        // if (run(tx.inputs[i].script_sig) == false) {
        return false
    };
    i = i + 1;
    // };
    true
}
