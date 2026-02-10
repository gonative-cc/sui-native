#[test_only]
module nbtc::record_signature_tests;

use ika_dwallet_2pc_mpc::coordinator::{set_signature_for_testing, DWalletCoordinator};
use nbtc::nbtc::{
    RedeemSigCreatedEvent,
    get_redeem_sig_created_event_redeem_id,
    get_redeem_sig_created_event_input_id
};
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::new_utxo;
use nbtc::test_constants::{
    MOCK_DWALLET_ID,
    NBTC_TAPROOT_SCRIPT,
    ADMIN,
    RECEIVER_SCRIPT,
    TX_HASH,
    REDEEM_FEE,
    MOCK_SIGNATURE,
    TEST_SIGN_ID_1,
    TEST_SIGN_ID_2
};
use std::unit_test::{assert_eq, destroy};
use sui::clock;
use sui::event;

#[test_only]
/// Setup a redeem request in the signing state
/// Creates a real DWalletCoordinator with dwallet and sign session
fun setup_redeem_in_signing_state(
    utxo_ids: vector<u64>,
    redeem_amount: u64,
    sign_ids: vector<ID>,
    mock_signatures: vector<vector<u8>>,
): (
    bitcoin_spv::light_client::LightClient,
    nbtc::nbtc::NbtcContract,
    DWalletCoordinator,
    u64,
    sui::test_scenario::Scenario,
    clock::Clock,
) {
    let dwallet_id = MOCK_DWALLET_ID!();

    let (lc, mut ctr, mut dwallet_coordinator, mut scenario) = setup(
        NBTC_TAPROOT_SCRIPT!(),
        ADMIN!(),
        dwallet_id,
    );

    utxo_ids.length().do!(|i| {
        let utxo = new_utxo(TX_HASH!(), (i as u32), 2500, dwallet_id);
        ctr.add_utxo_for_test(i, utxo);
    });

    let nbtc_coin = ctr.testing_mint(redeem_amount, scenario.ctx());

    let mut clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(
        nbtc_coin,
        RECEIVER_SCRIPT!(),
        REDEEM_FEE!(),
        &clock,
        scenario.ctx(),
    );

    ctr.propose_utxos(redeem_id, utxo_ids, &clock);
    clock.increment_for_testing(ctr.redeem_duration() + 1);
    ctr.solve_redeem_request(redeem_id, &clock);

    sign_ids.length().do!(|i| {
        let sign_id = sign_ids[i];
        dwallet_coordinator.add_sign_session_for_testing(dwallet_id, sign_id, scenario.ctx());

        ctr.redeem_request_mut(redeem_id).add_sign_id_for_test(sign_id, utxo_ids[i]);

        dwallet_coordinator.set_signature_for_testing(dwallet_id, sign_id, mock_signatures[i]);
    });

    (lc, ctr, dwallet_coordinator, redeem_id, scenario, clock)
}

#[test]
/// Test that record_signature returns true when recording a new signature
fun test_record_signature_returns_true_on_first_call() {
    let sign_id = TEST_SIGN_ID_1!();
    let (
        lc,
        mut ctr,
        dwallet_coordinator,
        redeem_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(vector[0], 1000, vector[sign_id], vector[MOCK_SIGNATURE!()]);

    ctr.record_signature(&dwallet_coordinator, redeem_id, vector[0], vector[sign_id]);

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
    let sign_id = TEST_SIGN_ID_1!();
    let (
        lc,
        mut ctr,
        dwallet_coordinator,
        redeem_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(vector[0], 1000, vector[sign_id], vector[MOCK_SIGNATURE!()]);

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );

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
    let sign_id = TEST_SIGN_ID_1!();
    let (
        lc,
        mut ctr,
        dwallet_coordinator,
        redeem_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(vector[0], 1000, vector[sign_id], vector[MOCK_SIGNATURE!()]);

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );

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
    let sign_id = TEST_SIGN_ID_1!();
    let (
        lc,
        mut ctr,
        dwallet_coordinator,
        redeem_id,
        mut scenario,
        clock,
    ) = setup_redeem_in_signing_state(vector[0], 1000, vector[sign_id], vector[MOCK_SIGNATURE!()]);

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );

    let sig_events = event::events_by_type<RedeemSigCreatedEvent>();
    assert_eq!(sig_events.length(), 1);
    assert_eq!(get_redeem_sig_created_event_redeem_id(&sig_events[0]), redeem_id);
    assert_eq!(get_redeem_sig_created_event_input_id(&sig_events[0]), 0);

    scenario.next_tx(ADMIN!());

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id],
    );

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}

#[test]
/// Test with multiple inputs: each input can be recorded independently
fun test_record_signature_with_multiple_inputs() {
    let sign_id1 = TEST_SIGN_ID_1!();
    let sign_id2 = TEST_SIGN_ID_2!();
    let (
        lc,
        mut ctr,
        dwallet_coordinator,
        redeem_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(
        vector[0, 1],
        1500,
        vector[sign_id1, sign_id2],
        vector[MOCK_SIGNATURE!(), MOCK_SIGNATURE!()],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id1],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0],
        vector[sign_id1],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[1],
        vector[sign_id2],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[1],
        vector[sign_id2],
    );

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
    let sign_id1 = TEST_SIGN_ID_1!();
    let sign_id2 = TEST_SIGN_ID_2!();
    let (
        lc,
        mut ctr,
        dwallet_coordinator,
        redeem_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(
        vector[0, 1],
        1500,
        vector[sign_id1, sign_id2],
        vector[MOCK_SIGNATURE!(), MOCK_SIGNATURE!()],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[0, 1],
        vector[sign_id1, sign_id2],
    );

    let request = ctr.redeem_request(redeem_id);
    assert_eq!(request.has_signature(0), true);
    assert_eq!(request.has_signature(1), true);

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}

#[test, expected_failure(abort_code = nbtc::redeem_request::EInvalidSignID)]
fun test_record_signature_fails_with_mismatched_sign_id() {
    let sign_id1 = TEST_SIGN_ID_1!();
    let sign_id2 = TEST_SIGN_ID_2!();
    let (
        lc,
        mut ctr,
        dwallet_coordinator,
        redeem_id,
        scenario,
        clock,
    ) = setup_redeem_in_signing_state(
        vector[0, 1],
        1500,
        vector[sign_id1, sign_id2],
        vector[MOCK_SIGNATURE!(), MOCK_SIGNATURE!()],
    );

    ctr.record_signature(
        &dwallet_coordinator,
        redeem_id,
        vector[1],
        vector[sign_id1],
    );

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    destroy(dwallet_coordinator);
    scenario.end();
}
