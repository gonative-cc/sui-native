#[test_only]
module nbtc::e2e_tests;

use ika_common::advance_epoch_approver::create;
use ika_dwallet_2pc_mpc::ika_dwallet_2pc_mpc_init::{init_for_testing, initialize_for_testing};
use nbtc::nbtc::NBTC;
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::new_utxo;
use sui::coin::mint_for_testing;
use sui::test_scenario::{Self, take_from_address, Scenario};
use sui::test_utils::destroy;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";

const ADMIN: address = @0xad;

fun create_dwallet_system(mut scenario: Scenario): Scenario {
    init_for_testing(scenario.ctx());
    // scenario.next_tx(ADMIN);
    // let init_cap = scenario.take_from_sender();
    // let mut advance_epoch_approver = create(0, );
    //
    // let system_current_status_info = 0;
    // let pricing = 0;
    // initialize_for_testing(
    //     init_cap,
    //     &mut advance_epoch_approver,
    //     &system_current_status_info,
    //     pricing,
    //     supported_curves_to_signature_algorithms_to_hash_schemes,
    //     scenario.ctx(),
    // );
    scenario
}
#[test]
fun redeem_happy_case() {
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, ADMIN);

    ctr.add_utxo_for_test(
        0,
        new_utxo(x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6", 0, 1500),
    );

    // create 1000sat NBCT token for test
    let nbtc_coin = mint_for_testing<NBTC>(1000, scenario.ctx());
    let receiver_spend_key = x"00140000000000000000000000000000000000000002";
    let redeem_id = ctr.redeem(nbtc_coin, receiver_spend_key, scenario.ctx());

    // TODO: proposal UTXO

    let inputs = vector[
        new_utxo(x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6", 0, 1500),
    ];
    // ctr.move_to_signing(redeem_id, inputs);

    // TODO::
    // - Create Dwallet Codinator
    // - Handle sign request
    // - Update signature
    // - valiadate the raw tx after signed tx
    // - bun NBTC token
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
