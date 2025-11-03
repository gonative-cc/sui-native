#[test_only]
module nbtc::redeem_request_tests;

use ika_dwallet_2pc_mpc::coordinator_inner::dwallet_cap_for_testing;
use nbtc::nbtc::{AdminCap, admin_cap_for_testing};
use nbtc::nbtc_tests::setup;
use sui::test_scenario::{take_from_address, return_to_address};
use sui::test_utils::destroy;

#[test]
fun raw_withdraw_tx_signed_tests() {
    let ntc_spend_key = x"";
    let sender = @0x1;
    let (lc, mut ctr, mut scenario) = setup(ntc_spend_key, sender);

    scenario.next_tx(sender);

    let admin_cap = admin_cap_for_testing(scenario.ctx());
    // mock dwallet id
    let dwallet = object::new(scenario.ctx());
    let dwallet_id = dwallet.uid_to_inner();
    let dwallet_cap = dwallet_cap_for_testing(dwallet_id, scenario.ctx());

    admin_cap.add_dwallet_cap(&mut ctr, dwallet_cap, ntc_spend_key, x"");
    let request_id = 0;

    let btc_receiver = x"";
    let inputs = vector[];
    let signatures = vector[];
    let amount = 0;
    ctr.create_redeem_request_for_testing(
        request_id,
        sender,
        btc_receiver,
        amount,
        inputs,
        signatures,
        scenario.ctx(),
    );

    let raw_tx = ctr.raw_signed_tx(request_id);
    std::debug::print(&raw_tx);
    destroy(lc);
    destroy(ctr);
    destroy(dwallet);
    destroy(admin_cap);
    scenario.end();
}
