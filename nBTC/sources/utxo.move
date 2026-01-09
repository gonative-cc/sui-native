// TODO: Refactor to bitcoinlib
module nbtc::nbtc_utxo;

use bitcoin_lib::encoding::u64_to_be_bytes;
use sui::table::{Self, Table};

//
// Errors
//

#[error]
const EEmptyUtxoSet: vector<u8> = b"UTXO set cannot be empty";

#[error]
const EInvalidUtxo: vector<u8> = b"Invalid UTXO";

#[error]
const EInsufficientAmount: vector<u8> = b"Total UTXO value is insufficient for withdrawal amount";

#[error]
const EDwalletIdMismatch: vector<u8> = b"UTXO dwallet_id mismatch";

#[error]
const EUtxoLockedByAnotherRequest: vector<u8> = b"UTXO is locked by another redeem request";

#[error]
const EInputLimitation: vector<u8> = b"Redeem request exceeds maximum input limit";

// UTXO ranking constants
const DUST_THRESHOLD: u64 = 10_000; // satoshis
const BASE_SCORE: u64 = 4_000_000_000_000_000; // 4e15
const INPUTS_PENALTY: u64 = 100;
const INACTIVE_BONUS: u64 = 200;
const NO_CHANGE_BONUS: u64 = 1_000;
const DUST_PENALTY: u64 = 200;
const MAXIMUM_NUMBER_UTXO: u64 = 100; // Maximum number of UTXO inputs allowed per redeem request transaction

public struct Utxo has store {
    tx_id: vector<u8>,
    vout: u32,
    value: u64,
}

public struct UtxoStore has key, store {
    id: UID,
    // Mapping (utxo_idx + dwallet_id) => Utxo
    utxos: Table<vector<u8>, Utxo>,
    // mapping ukey (utxo_idx + dwallet_id) => redeem_request_id
    locked_utxos: Table<vector<u8>, u64>,
    next_utxo: u64,
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

public(package) fun burn(utxo: Utxo) {
    let Utxo { tx_id: _, vout: _, value: _ } = utxo;
}

public(package) fun new_utxo_store(ctx: &mut TxContext): UtxoStore {
    UtxoStore {
        id: object::new(ctx),
        utxos: table::new(ctx),
        next_utxo: 0,
        locked_utxos: table::new(ctx),
    }
}

public(package) fun lock_utxo(
    utxo_store: &mut UtxoStore,
    idx: u64,
    dwallet_id: ID,
    redeem_request_id: u64,
) {
    let ukey = utxo_key(idx, dwallet_id);
    utxo_store.locked_utxos.add(ukey, redeem_request_id);
}

public(package) fun unlock_utxo(utxo_store: &mut UtxoStore, idx: u64, dwallet_id: ID) {
    let ukey = utxo_key(idx, dwallet_id);
    utxo_store.locked_utxos.remove(ukey);
}

public(package) fun utxo_key(idx: u64, dwallet_id: ID): vector<u8> {
    let mut ukey = u64_to_be_bytes(idx);
    ukey.append(dwallet_id.id_to_bytes());
    ukey
}

public(package) fun add(utxo_store: &mut UtxoStore, dwallet_id: ID, utxo: Utxo) {
    utxo_store.utxos.add(utxo_key(utxo_store.next_utxo, dwallet_id), utxo);
    utxo_store.next_utxo = utxo_store.next_utxo + 1;
}

public(package) fun remove(utxo_store: &mut UtxoStore, idx: u64, dwallet_id: ID): Utxo {
    utxo_store.utxos.remove(utxo_key(idx, dwallet_id))
}

public(package) fun contains(utxo_store: &UtxoStore, ukey: vector<u8>): bool {
    utxo_store.utxos.contains(ukey)
}

public(package) fun get_utxo(utxo_store: &UtxoStore, idx: u64, dwallet_id: ID): &Utxo {
    &utxo_store.utxos[utxo_key(idx, dwallet_id)]
}

public(package) fun get_utxo_by_ukey(utxo_store: &UtxoStore, ukey: vector<u8>): &Utxo {
    &utxo_store.utxos[ukey]
}

public fun next_utxo(utxo_store: &UtxoStore): u64 {
    utxo_store.next_utxo
}

/// Criteria:
///  Prefer fewer inputs
///  Avoid creating dust change
///  Prefer spending from inactive keys
///  Prefer exact matches
public fun utxo_ranking(
    utxo_store: &UtxoStore,
    utxo_ids: vector<u64>,
    dwallet_ids: vector<ID>,
    withdraw_amount: u64,
    active_dwallet_id: ID,
): u64 {
    let number_utxo = utxo_ids.length();
    let mut sum: u64 = 0;
    number_utxo.do!(|i| {
        let utxo = utxo_store.get_utxo(utxo_ids[i], dwallet_ids[i]);
        sum = sum + utxo.value();
    });
    if (sum < withdraw_amount) {
        return 0
    };
    let change = sum - withdraw_amount;
    let mut score = BASE_SCORE;
    score = score - (number_utxo * INPUTS_PENALTY);
    number_utxo.do!(|i| {
        if (dwallet_ids[i] != active_dwallet_id) {
            score = score + INACTIVE_BONUS;
        };
    });
    if (change == 0) {
        score = score + NO_CHANGE_BONUS;
    } else if (change < DUST_THRESHOLD) {
        score = score - DUST_PENALTY;
    };
    score
}

/// Validates a set of proposed UTXOs for withdrawal request.
/// Returns the sum of input amounts.
///
/// Checks performed:
/// 1. Ensures UTXO on chain set is not empty
/// 2. Validates each UTXO's structure
/// 3. Validates that total value is sufficient for withdrawal amount
/// 4. Validates that all UTXOs exist in the onchain UTXO set
/// 5. Validates that UTXOs are not locked by another redeem request
///
public fun validate_utxos(
    utxo_store: &UtxoStore,
    utxo_ids: &vector<u64>,
    dwallet_ids: vector<ID>,
    withdrawal_amount: u64,
    redeem_request_id: u64,
): u64 {
    assert!(!utxo_ids.is_empty(), EEmptyUtxoSet);
    assert!(utxo_ids.length() == dwallet_ids.length(), EDwalletIdMismatch);
    assert!(utxo_ids.length() <= MAXIMUM_NUMBER_UTXO, EInputLimitation);

    let mut total_value: u64 = 0;
    utxo_ids.length().do!(|i| {
        let idx = utxo_ids[i];
        let dwallet_id = dwallet_ids[i];
        let ukey = utxo_key(idx, dwallet_id);
        assert!(utxo_store.contains(ukey), EInvalidUtxo);

        if (utxo_store.locked_utxos.contains(ukey)) {
            assert!(
                utxo_store.locked_utxos[ukey] == redeem_request_id,
                EUtxoLockedByAnotherRequest,
            );
        };

        let utxo = utxo_store.get_utxo_by_ukey(ukey);

        total_value = total_value + utxo.value();
    });

    assert!(total_value >= withdrawal_amount, EInsufficientAmount);

    total_value
}
