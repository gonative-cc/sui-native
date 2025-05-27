module bitcoin_executor::types;

/// Represents a tx output reference
/// https://arc.net/l/quote/dgmqvdjx
public struct TxOutPoint has copy, drop, store {
    /// The hash of the tx where the output is being spend (TX_ID)
    hash: vector<u8>,
    /// the index of the output in that tx (VOUT)
    index: u32,
}

/// Represents a tx input.
public struct TxIn has copy, drop, store {
    /// Reference to the output being spent.
    prev_output: TxOutPoint,
    /// for SegWit this will be empty
    /// https://learnmeabitcoin.com/technical/transaction/input/scriptsig/
    script_sig: vector<u8>,
    /// tx version
    sequence: u32,
    //TODO: maybe we need witness here?
}

/// Represents a tx output
public struct TxOut has copy, drop, store {
    /// in satoshi
    value: u64,
    /// script that locks the output (scriptPubKey)
    /// https://learnmeabitcoin.com/technical/script/
    script_pub_key: vector<u8>,
}

/// Represents tx
public struct Transaction has copy, drop, store {
    version: u32,
    inputs: vector<TxIn>,
    outputs: vector<TxOut>,
    lock_time: u32,
}
