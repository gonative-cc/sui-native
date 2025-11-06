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
const EZeroValue: vector<u8> = b"UTXO value must be greater than zero";

#[error]
const EInsufficientAmount: vector<u8> = b"Total UTXO value is insufficient for withdrawal amount";

// TODO: we need to store them by owner (the nBTC key)?
public struct Utxo has copy, drop, store {
    tx_id: vector<u8>, // TODO: this is 32-byte hash. we can also use vector<u8>
    vout: u32,
    value: u64,
}

public fun new_utxo(tx_id: vector<u8>, vout: u32, value: u64): Utxo {
    Utxo {
        tx_id,
        vout,
        value,
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
