module bitcoin_executor::tx;

use bitcoin_executor::interpreter::run;
use bitcoin_executor::types::Tx;

/// Validate BTC transaction
public fun execute(tx: Tx): bool {
    let mut i = 0;
    while (i < tx.inputs().length()) {
        if (run(*tx.inputs()[i].script_sig()) == false) {
            return false
        };
        i = i + 1;
    };
    true
}
