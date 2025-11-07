// TODO: Refactor to bitcoinlib
module nbtc::nbtc_utxo;

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

/// # Criterias:
/// 1. Prefer fewer inputs
/// 2. Avoid creating dust change
/// 3. Prefer spending from inactive keys
/// 4. Prefer exact matches
public fun utxo_ranking(
    utxos: &vector<Utxo>,
    utxo_spend_keys: &vector<vector<u8>>,
    withdraw_amount: u64,
    active_spend_key: &vector<u8>,
): u64 {
    let dust_threshold: u64 = 10_000; // satoshis
    let base_score: u64 = 4_000_000_000_000_000; // 4e15
    let inputs_penalty: u64 = 100;
    let inactive_bonus: u64 = 200;
    let no_change_bonus: u64 = 1_000;
    let dust_penalty: u64 = 200;

    let mut sum: u64 = 0;
    let mut i = 0;
    let len = vector::length(utxos);
    while (i < len) {
        sum = sum + vector::borrow(utxos, i).value;
        i = i + 1;
    };

    if (sum < withdraw_amount) {
        return 0
    };

    let change = sum - withdraw_amount;
    let mut score = base_score;

    // 1) Fewer inputs
    let inputs = vector::length(utxos);
    score = score - (inputs * inputs_penalty);

    // 2) Prefer inactive keys
    i = 0;
    while (i < vector::length(utxo_spend_keys)) {
        if (vector::borrow(utxo_spend_keys, i) != active_spend_key) {
            score = score + inactive_bonus;
        };
        i = i + 1;
    };

    // 3) Change shaping
    if (change == 0) {
        // Perfect match
        score = score + no_change_bonus;
    } else if (change < dust_threshold) {
        score = score - dust_penalty;
    };

    score
}
