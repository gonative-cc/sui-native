#[test_only]
module nbtc::record_signature_tests;

use nbtc::nbtc::NBTC;
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::new_utxo;
use nbtc::test_constants::MOCK_DWALLET_ID;
use std::unit_test::{assert_eq, destroy};
use sui::clock;
use sui::coin::mint_for_testing;
use sui::test_utils::assert_eq as assert_ref_eq;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";
const ADMIN: address = @0xad;
const RECEIVER_SCRIPT: vector<u8> = x"00140000000000000000000000000000000000000002";
const TX_HASH: vector<u8> = x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6";
const REDEEM_FEE: u64 = 150;

const MOCK_SIGNATURE: vector<u8> =
    x"b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae";

#[test_only]
/// Setup a redeem request in the signing state with one UTXO
fun setup_redeem_in_signing_state(
    utxo_amount: u64,
    redeem_amount: u64,
): (
    bitcoin_spv::light_client::LightClient,
    nbtc::nbtc::NbtcContract,
    u64,
    sui::test_scenario::Scenario,
    clock::Clock,
) {
    let dwallet_id = MOCK_DWALLET_ID!();

    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, ADMIN, dwallet_id);

    let utxo = new_utxo(TX_HASH, 0, utxo_amount, dwallet_id);
    ctr.add_utxo_for_test(0, utxo);

    let nbtc_coin = ctr.testing_mint(redeem_amount, scenario.ctx());

    let mut clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    // Move to signing state
    ctr.propose_utxos(redeem_id, vector[0], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    (lc, ctr, redeem_id, scenario, clock)
}

#[test]
/// Test that record_signature returns true when recording a new signature
fun test_record_signature_returns_true_on_first_call() {
    let (lc, mut ctr, redeem_id, scenario, clock) = setup_redeem_in_signing_state(2500, 1000);

    // First call should return true (signature is recorded)
    let result = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result, true);

    // Verify the signature was actually recorded
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
/// Test that record_signature returns false when signature already recorded
fun test_record_signature_returns_false_when_already_recorded() {
    let (lc, mut ctr, redeem_id, scenario, clock) = setup_redeem_in_signing_state(2500, 1000);

    // First call - should return true
    let result1 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result1, true);

    // Second call with same input_id - should return false (idempotent)
    let result2 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result2, false);

    // Verify the signature is still there (only recorded once)
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
/// Test that calling record_signature multiple times is safe and idempotent
fun test_record_signature_multiple_calls_safe() {
    let (lc, mut ctr, redeem_id, scenario, clock) = setup_redeem_in_signing_state(2500, 1000);

    // First call - should return true
    let result1 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result1, true);

    // Call multiple times with same input_id - all should return false
    let result2 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result2, false);

    let result3 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result3, false);

    let result4 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result4, false);

    // Verify the signature is still valid after multiple calls
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
/// Test that events are emitted correctly: once on first call, not on subsequent calls
fun test_record_signature_event_emission() {
    let (lc, mut ctr, redeem_id, mut scenario, clock) = setup_redeem_in_signing_state(2500, 1000);

    // First call - should emit event
    let result1 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result1, true);

    // Move to next transaction to check events
    scenario.next_tx(ADMIN);

    // Second call - should NOT emit event (early return)
    let result2 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result2, false);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
/// Test with multiple inputs: each input can be recorded independently
fun test_record_signature_with_multiple_inputs() {
    let dwallet_id = MOCK_DWALLET_ID!();
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, ADMIN, dwallet_id);

    // Add two UTXOs
    let utxo1 = new_utxo(TX_HASH, 0, 1000, dwallet_id);
    ctr.add_utxo_for_test(0, utxo1);

    let utxo2 = new_utxo(x"02ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6", 1, 1000, dwallet_id);
    ctr.add_utxo_for_test(1, utxo2);

    let nbtc_coin = mint_for_testing<NBTC>(1500, scenario.ctx());
    let clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    // Move to signing state with both UTXOs
    ctr.propose_utxos(redeem_id, vector[0, 1], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    // Record signature for input 0 - should return true
    let result1 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result1, true);

    // Try to record again for input 0 - should return false
    let result2 = ctr.record_signature_for_test(redeem_id, 0, MOCK_SIGNATURE);
    assert_eq!(result2, false);

    // Record signature for input 1 - should return true (different input)
    let result3 = ctr.record_signature_for_test(redeem_id, 1, MOCK_SIGNATURE);
    assert_eq!(result3, true);

    // Try to record again for input 1 - should return false
    let result4 = ctr.record_signature_for_test(redeem_id, 1, MOCK_SIGNATURE);
    assert_eq!(result4, false);

    // Verify both signatures are recorded
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);
    assert_eq!(request.has_signature(1), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
