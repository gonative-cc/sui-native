#[test_only]
module nbtc::redeem_request_tests;

use nbtc::nbtc_tests::setup;
use sui::test_utils::destroy;

#[test]
fun raw_withdraw_tx_signed_tests() {
    let ntc_spend_key = x"";
    let sender = @0x1;
    let (lc, mut ctr, mut scenario) = setup(ntc_spend_key, sender);

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
