#[test_only]
module nbtc::redeem_workflow_tests;

use nbtc::nbtc::NBTC;
use nbtc::nbtc_tests::{setup, setup_with_pubkey};
use nbtc::nbtc_utxo::new_utxo;
use nbtc::storage;
use nbtc::test_constants::MOCK_DWALLET_ID;
use std::unit_test::{assert_eq, destroy};
use sui::clock;
use sui::coin::mint_for_testing;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";
const NBTC_TAPROOT_SCRIPT: vector<u8> =
    x"51200f0c8db753acbd17343a39c2f3f4e35e4be6da749f9e35137ab220e7b238a667";
const ADMIN: address = @0xad;
const RECEIVER_SCRIPT: vector<u8> = x"00140000000000000000000000000000000000000002";
const TX_HASH: vector<u8> = x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6";
const REDEEM_FEE: u64 = 150;

#[test_only]
fun setup_redeem_test(
    utxo_amount: u64,
    redeem_amount: u64,
    lockscript: vector<u8>,
    proceed_to_signed: bool,
): (
    bitcoin_spv::light_client::LightClient,
    nbtc::nbtc::NbtcContract,
    u64,
    sui::test_scenario::Scenario,
    clock::Clock,
) {
    let dwallet_id = MOCK_DWALLET_ID!();

    let mut temp_scenario = sui::test_scenario::begin(ADMIN);
    let dwallet_metadata = storage::create_dwallet_metadata(
        lockscript,
        vector::empty(),
        temp_scenario.ctx(),
    );
    temp_scenario.end();

    let (lc, mut ctr, mut scenario) = setup_with_pubkey(
        ADMIN,
        dwallet_id,
        dwallet_metadata,
    );

    let utxo = new_utxo(TX_HASH, 0, utxo_amount, dwallet_id);
    ctr.add_utxo_for_test(0, utxo);

    let nbtc_coin = ctr.testing_mint(redeem_amount, scenario.ctx());

    let mut clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    if (proceed_to_signed) {
        ctr.propose_utxos(redeem_id, vector[0], &clock);
        clock.increment_for_testing(ctr.redeem_duration() + 1);
        ctr.solve_redeem_request(redeem_id, &clock);

        let request_mut = ctr.redeem_request_mut(redeem_id);
        let mock_sig =
            x"b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae";
        request_mut.update_to_signed_for_test(vector[mock_sig]);
    };

    (lc, ctr, redeem_id, scenario, clock)
}

#[test]
fun test_redeem_workflow_happy_case() {
    let (lc, mut ctr, redeem_id, scenario, mut clock) = setup_redeem_test(
        2500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_resolving(), true);

    let utxo_ids = vector[0];
    ctr.propose_utxos(redeem_id, utxo_ids, &clock);

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
    let (lc, mut ctr, redeem_id, scenario, mut clock) = setup_redeem_test(
        1500,
        1000,
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
    let (lc, mut ctr, redeem_id, scenario, clock) = setup_redeem_test(
        500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let utxo_ids = vector[0];
    ctr.propose_utxos(redeem_id, utxo_ids, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc::ERedeemWindowExpired)]
fun test_finalize_fails_before_deadline() {
    let (lc, mut ctr, redeem_id, scenario, clock) = setup_redeem_test(
        1500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let utxo_ids = vector[0];
    ctr.propose_utxos(redeem_id, utxo_ids, &clock);

    ctr.solve_redeem_request(redeem_id, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc::ENotResolving)]
fun test_propose_fails_when_not_resolving() {
    let (lc, mut ctr, redeem_id, scenario, mut clock) = setup_redeem_test(
        1500,
        1000,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let utxo_ids = vector[0];
    ctr.propose_utxos(redeem_id, utxo_ids, &clock);

    let redeem_duration = ctr.redeem_duration();
    clock.increment_for_testing(redeem_duration + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    ctr.propose_utxos(redeem_id, utxo_ids, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
fun test_propose_utxos_unlocks_old_and_locks_new() {
    let (lc, mut ctr, redeem_id, scenario, clock) = setup_redeem_test(
        1000,
        1500,
        NBTC_SCRIPT_PUBKEY,
        false,
    );

    let dwallet_id = ctr.active_dwallet_id();
    let utxo_1 = new_utxo(x"02", 1, 1000, dwallet_id);
    ctr.add_utxo_for_test(1, utxo_1);

    let utxo_2 = new_utxo(x"03", 0, 1000, dwallet_id);
    ctr.add_utxo_for_test(2, utxo_2);

    let utxo_3 = new_utxo(x"04", 1, 1000, dwallet_id);
    ctr.add_utxo_for_test(3, utxo_3);

    let sol1 = vector[0, 1];
    ctr.propose_utxos(redeem_id, sol1, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.utxo_ids(), sol1);

    let sol2 = vector[2, 3];
    ctr.propose_utxos(redeem_id, sol2, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.utxo_ids(), sol2);

    let utxo_map = ctr.borrow_utxo_map_for_test();
    let total = nbtc::nbtc_utxo::validate_utxos(
        utxo_map,
        &sol1,
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
    let utxo_1 = new_utxo(TX_HASH, 0, 2000, dwallet_id);
    ctr.add_utxo_for_test(0, utxo_1);

    let utxo_2 = new_utxo(x"01", 1, 2000, dwallet_id);
    ctr.add_utxo_for_test(1, utxo_2);

    let nbtc_coin_1 = mint_for_testing<NBTC>(1000, scenario.ctx());
    let clock = clock::create_for_testing(scenario.ctx());
    let redeem_id_1 = ctr.redeem(nbtc_coin_1, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    ctr.propose_utxos(redeem_id_1, vector[0], &clock);

    let nbtc_coin_2 = mint_for_testing<NBTC>(1000, scenario.ctx());
    let redeem_id_2 = ctr.redeem(nbtc_coin_2, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    ctr.propose_utxos(redeem_id_2, vector[0], &clock);

    abort
}

#[test, expected_failure(abort_code = nbtc::nbtc_utxo::EUtxoLockedByAnotherRequest)]
fun test_cannot_propose_overlapping_locked_utxos() {
    let (_lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, ADMIN, MOCK_DWALLET_ID!());

    let dwallet_id = MOCK_DWALLET_ID!();

    let utxo_1 = new_utxo(TX_HASH, 0, 2000, dwallet_id);
    ctr.add_utxo_for_test(0, utxo_1);

    let utxo_2 = new_utxo(x"01", 1, 2000, dwallet_id);
    ctr.add_utxo_for_test(1, utxo_2);

    let utxo_3 = new_utxo(x"02", 2, 2000, dwallet_id);
    ctr.add_utxo_for_test(2, utxo_3);

    let clock = clock::create_for_testing(scenario.ctx());

    let nbtc_coin_1 = mint_for_testing<NBTC>(1500, scenario.ctx());
    let redeem_id_1 = ctr.redeem(nbtc_coin_1, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());
    ctr.propose_utxos(redeem_id_1, vector[0, 1], &clock);

    let nbtc_coin_2 = mint_for_testing<NBTC>(1500, scenario.ctx());
    let redeem_id_2 = ctr.redeem(nbtc_coin_2, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    ctr.propose_utxos(redeem_id_2, vector[1, 2], &clock);

    abort
}

#[test]
fun test_finalize_redeem_burns_nbtc_and_removes_utxos() {
    let (mut lc, mut ctr, redeem_id, scenario, clock) = setup_redeem_test(
        2500,
        1000,
        NBTC_TAPROOT_SCRIPT,
        true,
    );

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
    ctr.finalize_redeem(&lc, redeem_id, vector[], 1, 0);
    let supply_after = ctr.total_supply();
    assert_eq!(supply_after, supply_before - 1000);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_confirmed(), true);

    let utxo_store = ctr.borrow_utxo_map_for_test();
    assert_eq!(utxo_store.contains(0), false);

    assert_eq!(utxo_store.contains(1), true);
    let change_utxo = utxo_store.get_utxo(1);
    assert_eq!(change_utxo.value(), 1500);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
fun test_finalize_redeem_no_change() {
    let (mut lc, mut ctr, redeem_id, scenario, clock) = setup_redeem_test(
        1000,
        1000,
        NBTC_TAPROOT_SCRIPT,
        true,
    );

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
        x"03000000",
    );
    lc.insert_headers(vector[header]);

    let supply_before = ctr.total_supply();
    ctr.finalize_redeem(&lc, redeem_id, vector[], 1, 0);
    let supply_after = ctr.total_supply();
    assert_eq!(supply_after, supply_before - 1000);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_confirmed(), true);

    let utxo_store = ctr.borrow_utxo_map_for_test();

    assert_eq!(utxo_store.contains(0), false);
    assert_eq!(utxo_store.contains(1), false);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc::EAlreadyConfirmed)]
fun test_finalize_redeem_fails_when_already_confirmed() {
    let (mut lc, mut ctr, redeem_id, _scenario, _clock) = setup_redeem_test(
        2500,
        1000,
        NBTC_TAPROOT_SCRIPT,
        true,
    );

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
    ctr.finalize_redeem(&lc, redeem_id, vector[], 1, 0);
    abort
}

#[test]
fun test_finalize_redeem_with_multiple_utxos() {
    let (mut lc, mut ctr, redeem_id, scenario, mut clock) = setup_redeem_test(
        1000,
        1000,
        NBTC_TAPROOT_SCRIPT,
        false,
    );

    let dwallet_id = ctr.active_dwallet_id();
    let utxo_2 = new_utxo(
        x"02ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6",
        1,
        800,
        dwallet_id,
    );
    ctr.add_utxo_for_test(1, utxo_2);

    ctr.propose_utxos(redeem_id, vector[0, 1], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    let request_mut = ctr.redeem_request_mut(redeem_id);
    let mock_sig =
        x"b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae";
    request_mut.update_to_signed_for_test(vector[mock_sig, mock_sig]);

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
    ctr.finalize_redeem(&lc, redeem_id, vector[], 1, 0);
    let supply_after = ctr.total_supply();
    assert_eq!(supply_after, supply_before - 1000);

    let utxo_store = ctr.borrow_utxo_map_for_test();
    assert_eq!(utxo_store.contains(0), false);
    assert_eq!(utxo_store.contains(1), false);

    assert_eq!(utxo_store.contains(2), true);
    let change_utxo = utxo_store.get_utxo(2);
    assert_eq!(change_utxo.value(), 800);

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.status().is_confirmed(), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
