#[test_only]
module nbtc::utxo_tests;

use nbtc::nbtc_utxo;
use nbtc::test_constants::MOCK_DWALLET_ID;
use std::unit_test::{assert_eq, destroy};
use sui::test_scenario as ts;

#[test]
fun validate_utxos_working_case() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = nbtc_utxo::new_utxo_store(ctx);

    let utxo_1 = nbtc_utxo::new_utxo(x"01", 0, 50000, MOCK_DWALLET_ID!());
    onchain_utxos.add(utxo_1);

    let utxo_2 = nbtc_utxo::new_utxo(x"02", 1, 30000, MOCK_DWALLET_ID!());
    onchain_utxos.add(utxo_2);

    let proposed_indices = vector[0, 1];
    let withdrawal_amount = 70000;

    let total_value = nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        withdrawal_amount,
        0,
    );

    assert_eq!(total_value, 80000);

    destroy(onchain_utxos);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc_utxo::EEmptyUtxoSet)]
fun validate_utxos_empty_indices() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = nbtc_utxo::new_utxo_store(ctx);

    let utxo = nbtc_utxo::new_utxo(x"01", 0, 50000, MOCK_DWALLET_ID!());
    onchain_utxos.add(utxo);

    let proposed_indices = vector[];

    nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        10000,
        0,
    );

    abort
}

#[test, expected_failure(abort_code = nbtc_utxo::EInvalidUtxo)]
fun validate_utxos_nonexistent_index() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let onchain_utxos = nbtc_utxo::new_utxo_store(ctx);
    let proposed_indices = vector[0u64];

    onchain_utxos.validate_utxos(
        &proposed_indices,
        10000,
        0,
    );

    abort
}

#[test, expected_failure(abort_code = nbtc_utxo::EInsufficientAmount)]
fun validate_utxos_insufficient_amount() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = nbtc_utxo::new_utxo_store(ctx);

    let utxo = nbtc_utxo::new_utxo(x"01", 0, 50000, MOCK_DWALLET_ID!());
    onchain_utxos.add(utxo);

    let proposed_indices = vector[0];

    nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        100000,
        0,
    );

    abort
}

#[test]
fun validate_utxos_exact_match() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = nbtc_utxo::new_utxo_store(ctx);

    let utxo = nbtc_utxo::new_utxo(x"01", 0, 50000, MOCK_DWALLET_ID!());
    onchain_utxos.add(utxo);

    let proposed_indices = vector[0];

    let total_value = nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        50000,
        0,
    );

    assert_eq!(total_value, 50000);

    destroy(onchain_utxos);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc_utxo::EUtxoLockedByAnotherRequest)]
fun test_locked_utxo_cannot_be_used_by_other_request() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut utxo_store = nbtc_utxo::new_utxo_store(ctx);

    let utxo = nbtc_utxo::new_utxo(x"01", 0, 100000, MOCK_DWALLET_ID!());
    utxo_store.add(utxo);
    nbtc_utxo::lock_utxo(&mut utxo_store, 0, 1);

    nbtc_utxo::validate_utxos(
        &utxo_store,
        &vector[0],
        50000,
        2,
    );

    abort
}

#[test]
fun test_same_request_can_reuse_locked_utxos() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut utxo_store = nbtc_utxo::new_utxo_store(ctx);

    let utxo_1 = nbtc_utxo::new_utxo(x"01", 0, 60000, MOCK_DWALLET_ID!());
    utxo_store.add(utxo_1);

    let utxo_2 = nbtc_utxo::new_utxo(x"02", 1, 40000, MOCK_DWALLET_ID!());
    utxo_store.add(utxo_2);

    nbtc_utxo::lock_utxo(&mut utxo_store, 0, 5);
    nbtc_utxo::lock_utxo(&mut utxo_store, 1, 5);

    let total_value = nbtc_utxo::validate_utxos(
        &utxo_store,
        &vector[0, 1],
        90000,
        5,
    );

    assert_eq!(total_value, 100000);

    destroy(utxo_store);
    scenario.end();
}
