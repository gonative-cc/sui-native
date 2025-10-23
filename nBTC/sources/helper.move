module nbtc::helper;

use bitcoin_executor::utxo::{OutPoint, Data as UTXOData};
use bitcoin_parser::tx::{Transaction, new_unsign_segwit_tx};

public fun compose_withdraw_unsign_tx(selected_utxos: &vector<OutPoint>): Transaction {
    new_unsign_segwit_tx(vector[], vector[], vector[])
}
