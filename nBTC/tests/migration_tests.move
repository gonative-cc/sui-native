// SPDX-License-Identifier: MPL-2.0

#[test_only]
module nbtc::migration_tests;

use bitcoin_spv::light_client::LightClient;
use ika_dwallet_2pc_mpc::coordinator_inner::dwallet_cap_for_testing;
use nbtc::nbtc::{Self, NbtcContract, AdminCap};
use nbtc::nbtc_tests;
use nbtc::nbtc_utxo::new_utxo;
use nbtc::redeem_request::{update_to_signed_for_test, is_migration};
use nbtc::storage;
use nbtc::test_constants::{
    MOCK_DWALLET_ID,
    MOCK_DWALLET_ID_2,
    NBTC_TAPROOT_SCRIPT,
    ADMIN,
    TX_HASH,
    TX_HASH_2,
    REDEEM_FEE,
    MOCK_SIGNATURE
};
use std::string;
use std::unit_test::{assert_eq, destroy};
use sui::clock;
use sui::test_scenario::Scenario;

#[test_only]
fun setup_migration_test_simple(
    utxo_amount: u64,
    lockscript: vector<u8>,
): (LightClient, NbtcContract, AdminCap, ID, Scenario, clock::Clock) {
    let recommended_dwallet_id = MOCK_DWALLET_ID!();

    let mut temp_scenario = sui::test_scenario::begin(ADMIN!());
    let recommended_dw = storage::create_dwallet(
        dwallet_cap_for_testing(recommended_dwallet_id, temp_scenario.ctx()),
        lockscript,
        0,
        vector::empty(),
        vector::empty(),
        vector::empty(),
        vector::empty(),
        string::utf8(b"tb1qrecommended"),
        temp_scenario.ctx(),
    );
    temp_scenario.end();

    let (lc, mut ctr, _dwallet_coordinator, mut scenario) = nbtc_tests::setup_with_dwallet(
        ADMIN!(),
        recommended_dwallet_id,
        recommended_dw,
    );

    let admin_cap = nbtc::admin_cap_for_testing(scenario.ctx());

    let utxo = new_utxo(TX_HASH!(), 0, utxo_amount, recommended_dwallet_id);
    ctr.add_utxo_for_test(0, utxo);

    let clock = clock::create_for_testing(scenario.ctx());

    destroy(_dwallet_coordinator);
    (lc, ctr, admin_cap, recommended_dwallet_id, scenario, clock)
}

#[test]
fun test_migrate_utxos_creates_request() {
    let (
        lc,
        mut ctr,
        admin_cap,
        _recommended_dwallet_id,
        mut scenario,
        clock,
    ) = setup_migration_test_simple(2500, NBTC_TAPROOT_SCRIPT!());

    let redeem_id = nbtc::migrate_utxos(
        &admin_cap,
        &mut ctr,
        vector[0u64],
        REDEEM_FEE!(),
        &clock,
        scenario.ctx(),
    );

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(is_migration(request), true);
    assert_eq!(request.status().is_resolving(), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(admin_cap);
    scenario.end();
}

#[test]
fun test_migrate_utxos_with_multiple_utxos() {
    let recommended_dwallet_id = MOCK_DWALLET_ID!();

    let mut temp_scenario = sui::test_scenario::begin(ADMIN!());
    let recommended_dw = storage::create_dwallet(
        dwallet_cap_for_testing(recommended_dwallet_id, temp_scenario.ctx()),
        NBTC_TAPROOT_SCRIPT!(),
        0,
        vector::empty(),
        vector::empty(),
        vector::empty(),
        vector::empty(),
        string::utf8(b"tb1qrecommended"),
        temp_scenario.ctx(),
    );
    temp_scenario.end();

    let (lc, mut ctr, _dwallet_coordinator, mut scenario) = nbtc_tests::setup_with_dwallet(
        ADMIN!(),
        recommended_dwallet_id,
        recommended_dw,
    );

    let admin_cap = nbtc::admin_cap_for_testing(scenario.ctx());

    let utxo_1 = new_utxo(TX_HASH!(), 0, 1000, recommended_dwallet_id);
    ctr.add_utxo_for_test(0, utxo_1);

    let utxo_2 = new_utxo(TX_HASH_2!(), 1, 1500, recommended_dwallet_id);
    ctr.add_utxo_for_test(1, utxo_2);

    let clock = clock::create_for_testing(scenario.ctx());

    let redeem_id = nbtc::migrate_utxos(
        &admin_cap,
        &mut ctr,
        vector[0u64, 1u64],
        REDEEM_FEE!(),
        &clock,
        scenario.ctx(),
    );

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.amount(), 2500);
    assert_eq!(request.utxo_ids().length(), 2);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(admin_cap);
    destroy(_dwallet_coordinator);
    scenario.end();
}

#[test, expected_failure]
fun test_finalize_redeem_fails_for_migration_request() {
    let (
        mut lc,
        mut ctr,
        admin_cap,
        _recommended_dwallet_id,
        mut scenario,
        mut clock,
    ) = setup_migration_test_simple(2500, NBTC_TAPROOT_SCRIPT!());

    let redeem_id = nbtc::migrate_utxos(
        &admin_cap,
        &mut ctr,
        vector[0u64],
        REDEEM_FEE!(),
        &clock,
        scenario.ctx(),
    );

    ctr.propose_utxos(redeem_id, vector[0u64], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    let request_mut = ctr.redeem_request_mut(redeem_id);
    let mock_sig = MOCK_SIGNATURE!();
    request_mut.update_to_signed_for_test(vector[mock_sig]);

    let r = ctr.redeem_request(redeem_id);
    let tx = r.compose_tx(ctr.storage());
    let tx_id = tx.tx_id();

    let parent_hash = lc.head_hash();
    let header = bitcoin_lib::header::create_header_for_test(
        x"00000020",
        parent_hash,
        tx_id,
        x"132ae858",
        x"ffff7f20",
        x"01000011",
    );
    lc.insert_headers(vector[header]);

    ctr.finalize_redeem(&lc, redeem_id, vector[], 1, 0);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(admin_cap);
    scenario.end();
}

#[test]
fun test_finalize_migration_creates_new_utxo() {
    let (
        mut lc,
        mut ctr,
        admin_cap,
        recommended_dwallet_id,
        mut scenario,
        mut clock,
    ) = setup_migration_test_simple(2500, NBTC_TAPROOT_SCRIPT!());

    let redeem_id = nbtc::migrate_utxos(
        &admin_cap,
        &mut ctr,
        vector[0u64],
        REDEEM_FEE!(),
        &clock,
        scenario.ctx(),
    );

    ctr.propose_utxos(redeem_id, vector[0u64], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    let request_mut = ctr.redeem_request_mut(redeem_id);
    let mock_sig = MOCK_SIGNATURE!();
    request_mut.update_to_signed_for_test(vector[mock_sig]);

    let r = ctr.redeem_request(redeem_id);
    let tx = r.compose_tx(ctr.storage());
    let tx_id = tx.tx_id();

    let parent_hash = lc.head_hash();
    let header = bitcoin_lib::header::create_header_for_test(
        x"00000020",
        parent_hash,
        tx_id,
        x"132ae858",
        x"ffff7f20",
        x"01000011",
    );
    lc.insert_headers(vector[header]);

    let supply_before = ctr.total_supply();
    ctr.finalize_migration(&lc, redeem_id, vector[], 1, 0);
    let supply_after = ctr.total_supply();

    assert_eq!(supply_after, supply_before);

    let utxo_store = ctr.borrow_utxo_map_for_test();
    assert_eq!(utxo_store.contains(0), false);
    assert_eq!(utxo_store.contains(1), true);

    let new_utxo = utxo_store.get_utxo(1);
    assert_eq!(new_utxo.dwallet_id() == recommended_dwallet_id, true);
    assert_eq!(new_utxo.value(), 2500 - REDEEM_FEE!());

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(admin_cap);
    scenario.end();
}

#[test]
fun test_finalize_migration_and_deactivate_separate() {
    let recommended_dwallet_id = MOCK_DWALLET_ID!();
    let other_dwallet_id = MOCK_DWALLET_ID_2!();

    let mut temp_scenario = sui::test_scenario::begin(ADMIN!());
    let other_dw = storage::create_dwallet(
        dwallet_cap_for_testing(other_dwallet_id, temp_scenario.ctx()),
        NBTC_TAPROOT_SCRIPT!(),
        0,
        vector::empty(),
        vector::empty(),
        vector::empty(),
        vector::empty(),
        string::utf8(b"tb1qother"),
        temp_scenario.ctx(),
    );
    temp_scenario.end();

    let (mut lc, mut ctr, _dwallet_coordinator, mut scenario) = nbtc_tests::setup_with_dwallet(
        ADMIN!(),
        other_dwallet_id,
        other_dw,
    );

    let mut temp_scenario2 = sui::test_scenario::begin(ADMIN!());
    let recommended_dw = storage::create_dwallet(
        dwallet_cap_for_testing(recommended_dwallet_id, temp_scenario2.ctx()),
        NBTC_TAPROOT_SCRIPT!(),
        0,
        vector::empty(),
        vector::empty(),
        vector::empty(),
        vector::empty(),
        string::utf8(b"tb1qrecommended"),
        temp_scenario2.ctx(),
    );
    temp_scenario2.end();

    ctr.set_dwallet_for_test(recommended_dw);

    let admin_cap = nbtc::admin_cap_for_testing(scenario.ctx());

    let utxo = new_utxo(TX_HASH!(), 0, 2500, other_dwallet_id);
    ctr.add_utxo_for_test(0, utxo);

    let mut clock = clock::create_for_testing(scenario.ctx());

    let redeem_id = nbtc::migrate_utxos(
        &admin_cap,
        &mut ctr,
        vector[0u64],
        REDEEM_FEE!(),
        &clock,
        scenario.ctx(),
    );

    ctr.propose_utxos(redeem_id, vector[0u64], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    let request_mut = ctr.redeem_request_mut(redeem_id);
    let mock_sig = MOCK_SIGNATURE!();
    request_mut.update_to_signed_for_test(vector[mock_sig]);

    let r = ctr.redeem_request(redeem_id);
    let tx = r.compose_tx(ctr.storage());
    let tx_id = tx.tx_id();

    let parent_hash = lc.head_hash();
    let header = bitcoin_lib::header::create_header_for_test(
        x"00000020",
        parent_hash,
        tx_id,
        x"132ae858",
        x"ffff7f20",
        x"01000011",
    );
    lc.insert_headers(vector[header]);

    assert_eq!(ctr.storage().is_inactive(other_dwallet_id), false);

    ctr.finalize_migration(&lc, redeem_id, vector[], 1, 0);

    nbtc::deactivate_dwallet(&admin_cap, &mut ctr, other_dwallet_id);

    assert_eq!(ctr.storage().is_inactive(other_dwallet_id), true);

    let utxo_store = ctr.borrow_utxo_map_for_test();
    assert_eq!(utxo_store.contains(1), true);
    let new_utxo = utxo_store.get_utxo(1);
    assert_eq!(new_utxo.dwallet_id() == recommended_dwallet_id, true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(admin_cap);
    destroy(_dwallet_coordinator);
    scenario.end();
}
