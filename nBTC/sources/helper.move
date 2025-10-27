module nbtc::helper;

use bitcoin_executor::utxo::{OutPoint, Data as UTXOData};
use bitcoin_parser::encoding::u32_to_le_bytes;
use bitcoin_parser::input;
use bitcoin_parser::output;
use bitcoin_parser::tx::{Transaction, new_unsign_segwit_tx};
use nbtc::nbtc::NbtcContract;

const DEFAULT_SEQUENCE: vector<u8> = x"ffffffff"; // no lock time, no Replace By Fee

public fun compose_withdraw_unsign_tx(
    nbtc_contract: &NbtcContract,
    selected_outpoints: vector<OutPoint>,
    receiver_spend_key: vector<u8>,
    withdraw_amount: u64,
    fee: u64,
): Transaction {
    let utxos_set = nbtc_contract.utxos();
    let mut total_spend = 0;
    let inps = selected_outpoints.map!(|outpoint| {
        let utxo = utxos_set[outpoint];
        total_spend = total_spend + utxo.output().amount();
        input::new(
            outpoint.tx_id(),
            u32_to_le_bytes(outpoint.vout()),
            vector::empty(), // Because utxos is segwit format so script_sig field is empty
            DEFAULT_SEQUENCE,
        )
    });

    let user_receive_amount = withdraw_amount - fee;
    let remain_amount = total_spend - withdraw_amount;

    let mut outs = vector[output::new(user_receive_amount, receiver_spend_key)];

    if (remain_amount > 0) {
        outs.push_back(output::new(remain_amount, nbtc_contract.bitcoin_spend_key()));
    };
    new_unsign_segwit_tx(inps, outs)
}
