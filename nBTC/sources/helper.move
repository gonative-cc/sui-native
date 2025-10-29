module nbtc::helper;

use bitcoin_parser::encoding::u32_to_le_bytes;
use bitcoin_parser::input;
use bitcoin_parser::output;
use bitcoin_parser::tx::{Transaction, new_unsign_segwit_tx};
use nbtc::nbtc::NbtcContract;
use nbtc::nbtc_utxo::Utxo;

// https://learnmeabitcoin.com/technical/transaction/input/sequence/
// It disables RBF and disables locktime field.
const DEFAULT_SEQUENCE: vector<u8> = x"ffffffff";

public fun compose_withdraw_tx(
    bitcoin_spend_key: vector<u8>,
    utxos: vector<Utxo>,
    receiver_spend_key: vector<u8>,
    withdraw_amount: u64,
    fee: u64,
): Transaction {
    let mut total_spend = 0;
    let mut inps = vector[];
    utxos.do!(|utxo| {
        total_spend = total_spend + utxo.value();
        let inp = input::new(
            utxo.tx_id(),
            u32_to_le_bytes(utxo.vout()),
            vector::empty(), // Because utxos is segwit format so script_sig field is empty
            DEFAULT_SEQUENCE,
        );
        inps.push_back(inp);
    });

    // user cover the fee
    let user_receive_amount = withdraw_amount - fee;
    let remain_amount = total_spend - withdraw_amount;

    // output for for receiver
    let mut outs = vector[output::new(user_receive_amount, receiver_spend_key)];

    if (remain_amount > 0) {
        outs.push_back(output::new(remain_amount, bitcoin_spend_key));
    };
    new_unsign_segwit_tx(inps, outs)
}
