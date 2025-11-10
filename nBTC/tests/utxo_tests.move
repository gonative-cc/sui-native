#[test_only]
module nbtc::utxo_tests;

use nbtc::nbtc_utxo;
use std::unit_test::assert_eq;
use sui::table;
use sui::test_scenario as ts;

#[test]
fun validate_utxos_working_case() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = table::new(ctx);

    let tx_id_1 = x"1111111111111111111111111111111111111111111111111111111111111111";
    let spend_key = x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb";
    let utxo_1 = nbtc_utxo::new_utxo(tx_id_1, 0, 50000, spend_key);
    onchain_utxos.add(0, utxo_1);

    let tx_id_2 = x"2222222222222222222222222222222222222222222222222222222222222222";
    let utxo_2 = nbtc_utxo::new_utxo(tx_id_2, 1, 30000, spend_key);
    onchain_utxos.add(1, utxo_2);

    let proposed_indices = vector[0, 1];
    let withdrawal_amount = 70000;

    let total_value = nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        withdrawal_amount,
    );

    assert_eq!(total_value, 80000);

    onchain_utxos.drop();
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc_utxo::EEmptyUtxoSet)]
fun validate_utxos_empty_indices() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = table::new(ctx);

    let tx_id = x"1111111111111111111111111111111111111111111111111111111111111111";
    let spend_key = x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb";
    let utxo = nbtc_utxo::new_utxo(tx_id, 0, 50000, spend_key);
    onchain_utxos.add(0, utxo);

    let proposed_indices = vector[];

    nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        10000,
    );

    abort
}

#[test, expected_failure(abort_code = nbtc_utxo::EInvalidUtxo)]
fun validate_utxos_nonexistent_index() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let onchain_utxos = table::new(ctx);
    let proposed_indices = vector[0u64];

    nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        10000,
    );

    abort
}

#[test, expected_failure(abort_code = nbtc_utxo::EInsufficientAmount)]
fun validate_utxos_insufficient_amount() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = table::new(ctx);

    let tx_id = x"1111111111111111111111111111111111111111111111111111111111111111";
    let spend_key = x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb";
    let utxo = nbtc_utxo::new_utxo(tx_id, 0, 50000, spend_key);
    onchain_utxos.add(0, utxo);

    let proposed_indices = vector[0];

    nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        100000,
    );

    abort
}

#[test]
fun validate_utxos_exact_match() {
    let mut scenario = ts::begin(@0x1);
    let ctx = scenario.ctx();

    let mut onchain_utxos = table::new(ctx);

    let tx_id = x"1111111111111111111111111111111111111111111111111111111111111111";
    let spend_key = x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb";
    let utxo = nbtc_utxo::new_utxo(tx_id, 0, 50000, spend_key);
    onchain_utxos.add(0, utxo);

    let proposed_indices = vector[0];

    let total_value = nbtc_utxo::validate_utxos(
        &onchain_utxos,
        &proposed_indices,
        50000,
    );

    assert_eq!(total_value, 50000);

    onchain_utxos.drop();
    scenario.end();
}
