// TODO: Refactor to bitcoinlib
module nbtc::nbtc_utxo;

use sui::table::Table;

//
// Errors
//

#[error]
const EEmptyUtxoSet: vector<u8> = b"UTXO set cannot be empty";

#[error]
const EInvalidUtxo: vector<u8> = b"Invalid UTXO";

#[error]
const EInsufficientAmount: vector<u8> = b"Total UTXO value is insufficient for withdrawal amount";

// UTXO ranking constants
const DUST_THRESHOLD: u64 = 10_000; // satoshis
const BASE_SCORE: u64 = 4_000_000_000_000_000; // 4e15
const INPUTS_PENALTY: u64 = 100;
const INACTIVE_BONUS: u64 = 200;
const NO_CHANGE_BONUS: u64 = 1_000;
const DUST_PENALTY: u64 = 200;

// TODO: we need to store them by owner (the nBTC key)?
public struct Utxo has copy, drop, store {
    tx_id: vector<u8>, // TODO: this is 32-byte hash. we can also use vector<u8>
    vout: u32,
    value: u64,
    spend_key: vector<u8>,
}

public fun new_utxo(tx_id: vector<u8>, vout: u32, value: u64, spend_key: vector<u8>): Utxo {
    Utxo {
        tx_id,
        vout,
        value,
        spend_key,
    }
}

public fun tx_id(utxo: &Utxo): vector<u8> {
    utxo.tx_id
}

public fun vout(utxo: &Utxo): u32 {
    utxo.vout
}

public fun value(utxo: &Utxo): u64 {
    utxo.value
}

public fun spend_key(utxo: &Utxo): vector<u8> {
    utxo.spend_key
}

/// # Criterias:
/// 1. Prefer fewer inputs
/// 2. Avoid creating dust change
/// 3. Prefer spending from inactive keys
/// 4. Prefer exact matches
public fun utxo_ranking(
    utxos: &vector<Utxo>,
    withdraw_amount: u64,
    active_spend_key: &vector<u8>,
): u64 {
    let mut sum: u64 = 0;
    utxos.length().do!(|i| {
        sum = sum + utxos[i].value;
    });

    if (sum < withdraw_amount) {
        return 0
    };

    let change = sum - withdraw_amount;
    let mut score = BASE_SCORE;

    // 1) Fewer inputs
    let number_inputs = utxos.length();
    score = score - (number_inputs * INPUTS_PENALTY);

    // 2) Prefer inactive keys
    utxos.length().do!(|i| {
        if (&utxos[i].spend_key != active_spend_key) {
            score = score + INACTIVE_BONUS;
        };
    });

    // 3) Change shaping
    if (change == 0) {
        // Perfect match
        score = score + NO_CHANGE_BONUS;
    } else if (change < DUST_THRESHOLD) {
        score = score - DUST_PENALTY;
    };

    score
}

/// Validates a set of proposed UTXOs for withdrawal request.
///
/// Checks performed:
/// 1. Ensures UTXO on chain set is not empty
/// 2. Validates each UTXO's structure
/// 3. Validates that total value is sufficient for withdrawal amount
/// 4. Validates that all UTXOs exist in the onchain UTXO set
///
public fun validate_utxos(
    onchain_utxos: &Table<u64, Utxo>,
    proposed_indices: &vector<u64>,
    withdrawal_amount: u64,
): u64 {
    assert!(!proposed_indices.is_empty(), EEmptyUtxoSet);

    let len = proposed_indices.length();
    let mut total_value: u64 = 0;
    let mut i = 0;

    while (i < len) {
        let idx = proposed_indices[i];

        // Check UTXO exists in onchain set
        assert!(onchain_utxos.contains(idx), EInvalidUtxo);
        let onchain_utxo = &onchain_utxos[idx];

        total_value = total_value + onchain_utxo.value();
        i = i + 1;
    };

    assert!(total_value >= withdrawal_amount, EInsufficientAmount);

    total_value
}
