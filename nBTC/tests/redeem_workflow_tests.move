#[test_only]
module nbtc::redeem_workflow_tests;

use nbtc::nbtc::NBTC;
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::new_utxo;
use std::unit_test::destroy;
use sui::clock;
use sui::coin::mint_for_testing;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";
const ADMIN: address = @0xad;
const RECEIVER_SCRIPT: vector<u8> = x"00140000000000000000000000000000000000000002";
const TX_HASH: vector<u8> = x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6";

#[test_only]
fun setup_redeem_test(
    utxo_amount: u64,
    redeem_amount: u64,
): (
    bitcoin_spv::light_client::LightClient,
    nbtc::nbtc::NbtcContract,
    u64,
    ID,
    sui::test_scenario::Scenario,
    clock::Clock,
) {
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, ADMIN);

    let dwallet_id = object::id_from_address(ADMIN);
    ctr.add_utxo_for_test(
        0,
        new_utxo(TX_HASH, 0, utxo_amount, NBTC_SCRIPT_PUBKEY, dwallet_id),
    );

    let nbtc_coin = mint_for_testing<NBTC>(redeem_amount, scenario.ctx());
    let clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, RECEIVER_SCRIPT, &clock, scenario.ctx());

    (lc, ctr, redeem_id, dwallet_id, scenario, clock)
}

#[test]
fun test_redeem_workflow_happy_case() {
    let (lc, mut ctr, redeem_id, dwallet_id, scenario, mut clock) = setup_redeem_test(2500, 1000);

    let request = ctr.redeem_request(redeem_id);
    assert!(request.status().is_resolving());

    let utxo_ids = vector[0];
    let dwallet_ids = vector[dwallet_id];
    ctr.propose_utxos(redeem_id, utxo_ids, dwallet_ids, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert!(request.status().is_resolving());
    assert!(request.inputs_length() == 1);

    let redeem_duration = ctr.redeem_duration();
    clock.increment_for_testing(redeem_duration + 1);

    ctr.finalize_redeem_request(redeem_id, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert!(request.status().is_signing());

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc::ENoUTXOsProposed)]
fun test_finalize_fails_with_no_utxos_proposed() {
    let (lc, mut ctr, redeem_id, _dwallet_id, scenario, mut clock) = setup_redeem_test(1500, 1000);

    let redeem_duration = ctr.redeem_duration();
    clock.increment_for_testing(redeem_duration + 1);
    ctr.finalize_redeem_request(redeem_id, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::nbtc_utxo::EInsufficientAmount)]
fun test_propose_fails_with_insufficient_amount() {
    let (lc, mut ctr, redeem_id, dwallet_id, scenario, clock) = setup_redeem_test(500, 1000);

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
    let (lc, mut ctr, redeem_id, dwallet_id, scenario, clock) = setup_redeem_test(1500, 1000);

    let utxo_ids = vector[0];
    let dwallet_ids = vector[dwallet_id];
    ctr.propose_utxos(redeem_id, utxo_ids, dwallet_ids, &clock);

    ctr.finalize_redeem_request(redeem_id, &clock);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
