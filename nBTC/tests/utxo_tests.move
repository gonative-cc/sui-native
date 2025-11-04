#[test_only]
module nbtc::utxo_tests;

use nbtc::nbtc_utxo::{Self, Utxo};
use sui::table::{Self, Table};
use sui::test_scenario::{Self as ts};

#[test]
fun test_validate_utxos_working_case() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = table::new<u64, Utxo>(ctx);

    let tx_id_1 = x"1111111111111111111111111111111111111111111111111111111111111111";
    let utxo_1 = nbtc_utxo::new_utxo(tx_id_1, 0, 50000);
    onchain_utxos.add(0, utxo_1);

    let tx_id_2 = x"2222222222222222222222222222222222222222222222222222222222222222";
    let utxo_2 = nbtc_utxo::new_utxo(tx_id_2, 1, 30000);
    onchain_utxos.add(1, utxo_2);

    let mut proposed_utxos = vector::empty<Utxo>();
    proposed_utxos.push_back(nbtc_utxo::new_utxo(tx_id_1, 0, 50000));
    proposed_utxos.push_back(nbtc_utxo::new_utxo(tx_id_2, 1, 30000));

    let proposed_indices = vector[0u64, 1u64];

    let withdrawal_amount = 70000;

    let total_value = nbtc_utxo::validate_utxos(
        &proposed_utxos,
        &onchain_utxos,
        &proposed_indices,
        withdrawal_amount,
    );

    assert!(total_value == 80000, 0);

    onchain_utxos.drop();
    scenario.end();
}

#[test]
#[expected_failure(abort_code = nbtc_utxo::EEmptyUtxoSet)]
fun test_validate_utxos_empty_set() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let onchain_utxos = table::new<u64, Utxo>(ctx);
    let proposed_utxos = vector::empty<Utxo>();
    let proposed_indices = vector::empty<u64>();

    nbtc_utxo::validate_utxos(
        &proposed_utxos,
        &onchain_utxos,
        &proposed_indices,
        10000,
    );

    onchain_utxos.drop();
    scenario.end();
}

#[test]
#[expected_failure(abort_code = nbtc_utxo::EInsufficientAmount)]
fun test_validate_utxos_insufficient_amount() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = table::new<u64, Utxo>(ctx);

    let tx_id = x"1111111111111111111111111111111111111111111111111111111111111111";
    let utxo = nbtc_utxo::new_utxo(tx_id, 0, 50000);
    onchain_utxos.add(0, utxo);

    let mut proposed_utxos = vector::empty<Utxo>();
    proposed_utxos.push_back(nbtc_utxo::new_utxo(tx_id, 0, 50000));

    let proposed_indices = vector[0u64];

    nbtc_utxo::validate_utxos(
        &proposed_utxos,
        &onchain_utxos,
        &proposed_indices,
        100000,
    );

    onchain_utxos.drop();
    scenario.end();
}

#[test]
#[expected_failure(abort_code = nbtc_utxo::EZeroValue)]
fun test_validate_utxos_zero_value() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = table::new<u64, Utxo>(ctx);

    let tx_id = x"1111111111111111111111111111111111111111111111111111111111111111";
    let utxo = nbtc_utxo::new_utxo(tx_id, 0, 0); 
    onchain_utxos.add(0, utxo);

    let mut proposed_utxos = vector::empty<Utxo>();
    proposed_utxos.push_back(nbtc_utxo::new_utxo(tx_id, 0, 0));

    let proposed_indices = vector[0u64];

    nbtc_utxo::validate_utxos(
        &proposed_utxos,
        &onchain_utxos,
        &proposed_indices,
        1000,
    );

    onchain_utxos.drop();
    scenario.end();
}

#[test]
fun test_validate_utxos_exact_match() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = table::new<u64, Utxo>(ctx);

    let tx_id = x"1111111111111111111111111111111111111111111111111111111111111111";
    let utxo = nbtc_utxo::new_utxo(tx_id, 0, 50000);
    onchain_utxos.add(0, utxo);

    let mut proposed_utxos = vector::empty<Utxo>();
    proposed_utxos.push_back(nbtc_utxo::new_utxo(tx_id, 0, 50000));

    let proposed_indices = vector[0u64];

    let total_value = nbtc_utxo::validate_utxos(
        &proposed_utxos,
        &onchain_utxos,
        &proposed_indices,
        50000,
    );

    assert!(total_value == 50000, 0);

    onchain_utxos.drop();
    scenario.end();
}
