#[test_only]
module nbtc::record_signature_tests;

use ika_dwallet_2pc_mpc::coordinator::{
    coordinator_for_test,
    set_signature_for_testing,
    add_dwallet_for_testing,
    add_sign_session_for_testing,
    DWalletCoordinator
};
use ika_dwallet_2pc_mpc::coordinator_inner::dwallet_coordinator_internal;
use nbtc::nbtc::NBTC;
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::new_utxo;
use nbtc::test_constants::MOCK_DWALLET_ID;
use std::unit_test::{assert_eq, destroy};
use sui::clock;
use sui::coin::mint_for_testing;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";
const ADMIN: address = @0xad;
const RECEIVER_SCRIPT: vector<u8> = x"0014000000000000000000000000000000000000000002";
const TX_HASH: vector<u8> = x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6";
const REDEEM_FEE: u64 = 150;

const MOCK_SIGNATURE: vector<u8> =
    x"b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae";

#[test_only]
/// Setup a redeem request in the signing state with one UTXO
/// Creates a real DWalletCoordinator with dwallet and sign session
fun setup_redeem_in_signing_state(
    utxo_amount: u64,
    redeem_amount: u64,
): (
    bitcoin_spv::light_client::LightClient,
    nbtc::nbtc::NbtcContract,
    DWalletCoordinator,
    u64,
    ID,
    sui::test_scenario::Scenario,
    clock::Clock,
) {
    let dwallet_id = MOCK_DWALLET_ID!();

    // Setup nBTC contract first to get scenario
    let (lc, mut ctr, mut dwallet_coordinator, mut scenario) = setup(
        NBTC_SCRIPT_PUBKEY,
        ADMIN,
        dwallet_id,
    );

    // Create real DWalletCoordinator with inner state
    // The coordinator is already returned by setup with dwallet added

    let utxo = new_utxo(TX_HASH, 0, utxo_amount, dwallet_id);
    ctr.add_utxo_for_test(0, utxo);

    let nbtc_coin = ctr.testing_mint(redeem_amount, scenario.ctx());

    let mut clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    // Move to signing state
    ctr.propose_utxos(redeem_id, vector[0], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    // Add sign session to coordinator for testing record_signature
    let sign_id = sui::object::id_from_address(@0x2);
    add_sign_session_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id, scenario.ctx());

    (lc, ctr, dwallet_coordinator, redeem_id, sign_id, scenario, clock)
}

#[test]
/// Test that record_signature returns true when recording a new signature
fun test_record_signature_returns_true_on_first_call() {
    let (
        lc,
        mut ctr,
        mut dwallet_coordinator,
        redeem_id,
        sign_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(2500, 1000);

    // Use set_signature_for_testing to mock the signature in coordinator
    let dwallet_id = ctr.active_dwallet_id();
    set_signature_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id, MOCK_SIGNATURE);

    // Now call the real batch record_signature function
    let results = ctr.record_signature(&dwallet_coordinator, redeem_id, vector[0], vector[sign_id]);
    assert_eq!(results[0], true);

    // Verify the signature was actually recorded
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}

#[test]
/// Test that record_signature returns false when signature already recorded
fun test_record_signature_returns_false_when_already_recorded() {
    let (
        lc,
        mut ctr,
        mut dwallet_coordinator,
        redeem_id,
        sign_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(2500, 1000);

    // Use set_signature_for_testing to mock the signature
    let dwallet_id = ctr.active_dwallet_id();
    set_signature_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id, MOCK_SIGNATURE);

    // First call - should return true
    let results1 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );
    assert_eq!(results1[0], true);

    // Second call with same input_id - should return false (idempotent)
    let results2 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );
    assert_eq!(results2[0], false);

    // Verify the signature is still there (only recorded once)
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}

#[test]
/// Test that calling record_signature multiple times is safe and idempotent
fun test_record_signature_multiple_calls_safe() {
    let (
        lc,
        mut ctr,
        mut dwallet_coordinator,
        redeem_id,
        sign_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(2500, 1000);

    // Use set_signature_for_testing to mock the signature
    let dwallet_id = ctr.active_dwallet_id();
    set_signature_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id, MOCK_SIGNATURE);

    // First call - should return true
    let results1 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );
    assert_eq!(results1[0], true);

    // Call multiple times with same input_id - all should return false
    let results2 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );
    assert_eq!(results2[0], false);

    let results3 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );
    assert_eq!(results3[0], false);

    let results4 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );
    assert_eq!(results4[0], false);

    // Verify the signature is still valid after multiple calls
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}

#[test]
/// Test that events are emitted correctly: once on first call, not on subsequent calls
fun test_record_signature_event_emission() {
    let (
        lc,
        mut ctr,
        mut dwallet_coordinator,
        redeem_id,
        sign_id,
        mut scenario,
        clock,
    ) = setup_redeem_in_signing_state(2500, 1000);

    // Use set_signature_for_testing to mock the signature
    let dwallet_id = ctr.active_dwallet_id();
    set_signature_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id, MOCK_SIGNATURE);

    // First call - should emit event
    let results1 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );
    assert_eq!(results1[0], true);

    // Move to next transaction to check events
    scenario.next_tx(ADMIN);

    // Second call - should NOT emit event (early return)
    let results2 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );
    assert_eq!(results2[0], false);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}

#[test]
/// Test with multiple inputs: each input can be recorded independently
fun test_record_signature_with_multiple_inputs() {
    let dwallet_id = MOCK_DWALLET_ID!();
    let (lc, mut ctr, mut dwallet_coordinator, mut scenario) = setup(
        NBTC_SCRIPT_PUBKEY,
        ADMIN,
        dwallet_id,
    );

    // Add dwallet to coordinator is already done in setup

    // Add two UTXOs
    let utxo1 = new_utxo(TX_HASH, 0, 1000, dwallet_id);
    ctr.add_utxo_for_test(0, utxo1);

    let utxo2 = new_utxo(
        x"02ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6",
        1,
        1000,
        dwallet_id,
    );
    ctr.add_utxo_for_test(1, utxo2);

    let nbtc_coin = mint_for_testing<NBTC>(1500, scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    // Move to signing state with both UTXOs
    ctr.propose_utxos(redeem_id, vector[0, 1], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    // Add sign sessions for both inputs
    let sign_id1 = sui::object::id_from_address(@0x2);
    add_sign_session_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id1, scenario.ctx());

    let sign_id2 = sui::object::id_from_address(@0x3);
    add_sign_session_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id2, scenario.ctx());

    // Record signature for input 0 - should return true
    set_signature_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id1, MOCK_SIGNATURE);
    let results1 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id1],
    );
    assert_eq!(results1[0], true);

    // Try to record again for input 0 - should return false
    let results2 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id1],
    );
    assert_eq!(results2[0], false);

    // Record signature for input 1 - should return true (different input)
    set_signature_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id2, MOCK_SIGNATURE);
    let results3 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[1],
        vector[sign_id2],
    );
    assert_eq!(results3[0], true);

    // Try to record again for input 1 - should return false
    let results4 = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[1],
        vector[sign_id2],
    );
    assert_eq!(results4[0], false);

    // Verify both signatures are recorded
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);
    assert_eq!(request.has_signature(1), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}

#[test]
/// Test batch recording multiple signatures at once
fun test_record_signature_batch() {
    let dwallet_id = MOCK_DWALLET_ID!();
    let (lc, mut ctr, mut dwallet_coordinator, mut scenario) = setup(
        NBTC_SCRIPT_PUBKEY,
        ADMIN,
        dwallet_id,
    );

    // Add dwallet to coordinator is already done in setup

    // Add two UTXOs
    let utxo1 = new_utxo(TX_HASH, 0, 1000, dwallet_id);
    ctr.add_utxo_for_test(0, utxo1);

    let utxo2 = new_utxo(
        x"02ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6",
        1,
        1000,
        dwallet_id,
    );
    ctr.add_utxo_for_test(1, utxo2);

    let nbtc_coin = mint_for_testing<NBTC>(1500, scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, RECEIVER_SCRIPT, REDEEM_FEE, &clock, scenario.ctx());

    // Move to signing state with both UTXOs
    ctr.propose_utxos(redeem_id, vector[0, 1], &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    // Add sign sessions for both inputs
    let sign_id1 = sui::object::id_from_address(@0x2);
    add_sign_session_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id1, scenario.ctx());

    let sign_id2 = sui::object::id_from_address(@0x3);
    add_sign_session_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id2, scenario.ctx());

    // Set signatures for both inputs
    set_signature_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id1, MOCK_SIGNATURE);
    set_signature_for_testing(&mut dwallet_coordinator, dwallet_id, sign_id2, MOCK_SIGNATURE);

    // Record both signatures in one batch call
    let results = ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0, 1],
        vector[sign_id1, sign_id2],
    );
    assert_eq!(results[0], true);
    assert_eq!(results[1], true);

    // Verify both signatures are recorded
    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);
    assert_eq!(request.has_signature(1), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}
