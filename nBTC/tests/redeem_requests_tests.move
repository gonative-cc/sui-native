#[test_only]
module nbtc::redeem_request_tests;

use nbtc::nbtc_tests::setup;
use sui::test_scenario::take_from_address;
use sui::test_utils::destroy;

#[test]
fun raw_withdraw_tx_signed_tests() {
    let ntc_spend_key = x"";
    let sender = @0x1;
    let (lc, mut ctr, mut scenario) = setup(ntc_spend_key, sender);

    scenario.next_tx(sender);

    let admin_cap = take_from_address(sender);
    admin_cap.add_dwallet_cap(&ctr, ntc_spend_key);
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
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
