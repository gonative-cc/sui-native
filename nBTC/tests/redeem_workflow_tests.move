#[test_only]
module nbtc::redeem_workflow_tests;

use bitcoin_lib::tx;
use nbtc::nbtc::NBTC;
use nbtc::nbtc_tests::{setup, setup_with_pubkey};
use nbtc::nbtc_utxo::{new_utxo, utxo_key};
use nbtc::storage;
use nbtc::test_constants::MOCK_DWALLET_ID;
use std::unit_test::{assert_eq, destroy};
use sui::clock;
use sui::coin::mint_for_testing;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";
const NBTC_P2WPKH_SCRIPT: vector<u8> = x"00145c2dc82f606be66506b7403f9b304f5e0908b652";
const NBTC_PUBLIC_KEY: vector<u8> =
    x"0329cdb63380e0a7109773703534659df6be41c48b4e80e5da77eb384ff7d41be2";
const ADMIN: address = @0xad;
const RECEIVER_SCRIPT: vector<u8> = x"00140000000000000000000000000000000000000002";
const TX_HASH: vector<u8> = x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6";

#[test_only]
fun setup_redeem_test(
    utxo_amount: u64,
    redeem_amount: u64,
    lockscript: vector<u8>,
    public_key: vector<u8>,
    proceed_to_signed: bool,
): (
    bitcoin_spv::light_client::LightClient,
    nbtc::nbtc::NbtcContract,
    u64,
    ID,
    sui::test_scenario::Scenario,
    clock::Clock,
) {
    let dwallet_id = MOCK_DWALLET_ID!();

    let mut temp_scenario = sui::test_scenario::begin(ADMIN);
    let dwallet_metadata = storage::create_dwallet_metadata(
        lockscript,
        public_key,
        vector::empty(),
        temp_scenario.ctx(),
    );
    temp_scenario.end();

    let (lc, mut ctr, mut scenario) = setup_with_pubkey(
        ADMIN,
        dwallet_id,
        dwallet_metadata,
    );

    let utxo = new_utxo(TX_HASH, 0, utxo_amount);
    ctr.add_utxo_for_test(0, utxo);

    let nbtc_coin = ctr.testing_mint(redeem_amount, scenario.ctx());

    let mut clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, RECEIVER_SCRIPT, &clock, scenario.ctx());

    if (proceed_to_signed) {
        ctr.propose_utxos(redeem_id, vector[0], vector[dwallet_id], &clock);
        clock.increment_for_testing(ctr.redeem_duration() + 1);
        ctr.solve_redeem_request(redeem_id, &clock);

        let request_mut = ctr.redeem_request_mut(redeem_id);
        let mock_sig =
            x"0063db5a24fec209152863fb251cc349a7030220bf4ca6e6296002d46d4c3651a55a0b4b5a520fc42b91b8a888351c1c42bd2864aba2c398007405e957dea77bb1";
        request_mut.update_to_signed_for_test(vector[mock_sig]);
    };

    (lc, ctr, redeem_id, dwallet_id, scenario, clock)
}

#[test]
fun test_redeem_workflow_happy_case() {
    let (lc, mut ctr, redeem_id, dwallet_id, scenario, mut clock) = setup_redeem_test(
        2500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_resolving(), true);

    let utxo_ids = vector[0];
    let dwallet_ids = vector[dwallet_id];
    ctr.propose_utxos(redeem_id, utxo_ids, dwallet_ids, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_resolving(), true);
    assert_eq!(request.inputs_length(), 1);

    let redeem_duration = ctr.redeem_duration();
    clock.increment_for_testing(redeem_duration + 1);

    ctr.solve_redeem_request(redeem_id, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_signing(), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc::ENoUTXOsProposed)]
fun test_finalize_fails_with_no_utxos_proposed() {
    let (lc, mut ctr, redeem_id, _dwallet_id, scenario, mut clock) = setup_redeem_test(
        1500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let redeem_duration = ctr.redeem_duration();
    clock.increment_for_testing(redeem_duration + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc_utxo::EInsufficientAmount)]
fun test_propose_fails_with_insufficient_amount() {
    let (lc, mut ctr, redeem_id, dwallet_id, scenario, clock) = setup_redeem_test(
        500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let utxo_ids = vector[0];
    let dwallet_ids = vector[dwallet_id];
    ctr.propose_utxos(redeem_id, utxo_ids, dwallet_ids, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc::ERedeemWindowExpired)]
fun test_finalize_fails_before_deadline() {
    let (lc, mut ctr, redeem_id, dwallet_id, scenario, clock) = setup_redeem_test(
        1500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let utxo_ids = vector[0];
    let dwallet_ids = vector[dwallet_id];
    ctr.propose_utxos(redeem_id, utxo_ids, dwallet_ids, &clock);

    ctr.solve_redeem_request(redeem_id, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc::ENotResolving)]
fun test_propose_fails_when_not_resolving() {
    let (lc, mut ctr, redeem_id, dwallet_id, scenario, mut clock) = setup_redeem_test(
        1500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let utxo_ids = vector[0];
    let dwallet_ids = vector[dwallet_id];
    ctr.propose_utxos(redeem_id, utxo_ids, dwallet_ids, &clock);

    let redeem_duration = ctr.redeem_duration();
    clock.increment_for_testing(redeem_duration + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    ctr.propose_utxos(redeem_id, utxo_ids, dwallet_ids, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
fun test_propose_utxos_unlocks_old_and_locks_new() {
    let (lc, mut ctr, redeem_id, dwallet_id, scenario, clock) = setup_redeem_test(
        1000,
        1500,
        NBTC_SCRIPT_PUBKEY,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let utxo_1 = new_utxo(x"02", 1, 1000);
    ctr.add_utxo_for_test(1, utxo_1);

    let utxo_2 = new_utxo(x"03", 0, 1000);
    ctr.add_utxo_for_test(2, utxo_2);

    let utxo_3 = new_utxo(x"04", 1, 1000);
    ctr.add_utxo_for_test(3, utxo_3);

    let sol1 = vector[0, 1];
    let sol1_dwallets = vector[dwallet_id, dwallet_id];
    ctr.propose_utxos(redeem_id, sol1, sol1_dwallets, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.utxo_ids(), sol1);

    let sol2 = vector[2, 3];
    let sol2_dwallets = vector[dwallet_id, dwallet_id];
    ctr.propose_utxos(redeem_id, sol2, sol2_dwallets, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.utxo_ids(), sol2);

    let utxo_map = ctr.borrow_utxo_map_for_test();
    let total = nbtc::nbtc_utxo::validate_utxos(
        utxo_map,
        &sol1,
        sol1_dwallets,
        1500,
        999,
    );
    assert_eq!(total, 2000);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc_utxo::EUtxoLockedByAnotherRequest)]
fun test_two_requests_cannot_share_utxos() {
    let (_lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, ADMIN, MOCK_DWALLET_ID!());

    let dwallet_id = MOCK_DWALLET_ID!();
    let utxo_1 = new_utxo(TX_HASH, 0, 2000);
    ctr.add_utxo_for_test(0, utxo_1);

    let utxo_2 = new_utxo(x"01", 1, 2000);
    ctr.add_utxo_for_test(1, utxo_2);

    let nbtc_coin_1 = mint_for_testing<NBTC>(1000, scenario.ctx());
    let clock = clock::create_for_testing(scenario.ctx());
    let redeem_id_1 = ctr.redeem(nbtc_coin_1, RECEIVER_SCRIPT, &clock, scenario.ctx());

    ctr.propose_utxos(redeem_id_1, vector[0], vector[dwallet_id], &clock);

    let nbtc_coin_2 = mint_for_testing<NBTC>(1000, scenario.ctx());
    let redeem_id_2 = ctr.redeem(nbtc_coin_2, RECEIVER_SCRIPT, &clock, scenario.ctx());

    ctr.propose_utxos(redeem_id_2, vector[0], vector[dwallet_id], &clock);

    abort
}

#[test, expected_failure(abort_code = nbtc::nbtc_utxo::EUtxoLockedByAnotherRequest)]
fun test_cannot_propose_overlapping_locked_utxos() {
    let (_lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, ADMIN, MOCK_DWALLET_ID!());

    let dwallet_id = MOCK_DWALLET_ID!();

    let utxo_1 = new_utxo(TX_HASH, 0, 2000);
    ctr.add_utxo_for_test(0, utxo_1);

    let utxo_2 = new_utxo(x"01", 1, 2000);
    ctr.add_utxo_for_test(1, utxo_2);

    let utxo_3 = new_utxo(x"02", 2, 2000);
    ctr.add_utxo_for_test(2, utxo_3);

    let clock = clock::create_for_testing(scenario.ctx());

    let nbtc_coin_1 = mint_for_testing<NBTC>(1500, scenario.ctx());
    let redeem_id_1 = ctr.redeem(nbtc_coin_1, RECEIVER_SCRIPT, &clock, scenario.ctx());
    ctr.propose_utxos(redeem_id_1, vector[0, 1], vector[dwallet_id, dwallet_id], &clock);

    let nbtc_coin_2 = mint_for_testing<NBTC>(1500, scenario.ctx());
    let redeem_id_2 = ctr.redeem(nbtc_coin_2, RECEIVER_SCRIPT, &clock, scenario.ctx());

    ctr.propose_utxos(redeem_id_2, vector[1, 2], vector[dwallet_id, dwallet_id], &clock);

    abort
}

#[test]
fun test_confirm_redeem_burns_nbtc_and_removes_utxos() {
    let (mut lc, mut ctr, redeem_id, dwallet_id, scenario, clock) = setup_redeem_test(
        2500,
        1000,
        NBTC_P2WPKH_SCRIPT,
        NBTC_PUBLIC_KEY,
        true,
    );

    let r = ctr.redeem_request(redeem_id);
    let tx_bytes = r.raw_signed_tx(ctr.storage());
    let tx = tx::decode(tx_bytes);
    let tx_id = tx.tx_id();
    let parent_hash = lc.head_hash();
    let header = bitcoin_lib::header::create_header_for_test(
        x"00000020",
        parent_hash,
        tx_id,
        x"132ae858",
        x"ffff7f20",
        x"01000000",
    );
    lc.insert_headers(vector[header]);

    let supply_before = ctr.total_supply();
    ctr.confirm_redeem(&lc, redeem_id, vector[], 1, 0);
    let supply_after = ctr.total_supply();
    assert_eq!(supply_after, supply_before - 1000);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_confirmed(), true);

    let utxo_store = ctr.borrow_utxo_map_for_test();
    assert_eq!(utxo_store.contains(utxo_key(0, dwallet_id)), false);

    let active_dwallet = ctr.active_dwallet_id();
    assert_eq!(utxo_store.contains(utxo_key(1, active_dwallet)), true);
    let change_utxo = utxo_store.get_utxo(1, active_dwallet);
    assert_eq!(change_utxo.value(), 1500);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
fun test_confirm_redeem_no_change() {
    let (mut lc, mut ctr, redeem_id, dwallet_id, scenario, clock) = setup_redeem_test(
        1000,
        1000,
        NBTC_P2WPKH_SCRIPT,
        NBTC_PUBLIC_KEY,
        true,
    );

    let r = ctr.redeem_request(redeem_id);
    let tx_bytes = r.raw_signed_tx(ctr.storage());
    let tx = tx::decode(tx_bytes);
    let tx_id = tx.tx_id();

    let parent_hash = lc.head_hash();
    let header = bitcoin_lib::header::create_header_for_test(
        x"00000020",
        parent_hash,
        tx_id,
        x"132ae858",
        x"ffff7f20",
        x"03000000",
    );
    lc.insert_headers(vector[header]);

    let supply_before = ctr.total_supply();
    ctr.confirm_redeem(&lc, redeem_id, vector[], 1, 0);
    let supply_after = ctr.total_supply();
    assert_eq!(supply_after, supply_before - 1000);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_confirmed(), true);

    let utxo_store = ctr.borrow_utxo_map_for_test();
    assert_eq!(utxo_store.contains(utxo_key(0, dwallet_id)), false);

    let active_dwallet = ctr.active_dwallet_id();
    assert_eq!(utxo_store.contains(utxo_key(1, active_dwallet)), false);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
