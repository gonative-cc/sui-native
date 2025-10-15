#[test_only]
module nbtc::redeem_tests;

use nbtc::nbtc::create_nbtc_for_testing;
use nbtc::nbtc_tests::setup;
use std::unit_test::assert_eq;
use sui::test_utils::destroy;

#[test]
fun create_redeem_request_happy_case() {
    let sender = @0x1;
    let value = 10000;
    let btc_receiver = b"This is mock receiver";
    let (_lc, mut contract, mut scenario) = setup(
        x"76a914509a651dd392e1bc125323f629b67d65cca3d4ff88ac",
        sender,
    );

    let redeem_coin = contract.create_nbtc_for_testing(value, scenario.ctx());

    let redeem_id = contract.request_redeem(redeem_coin, btc_receiver, scenario.ctx());
    let request = contract.redeem_request(redeem_id);

    assert_eq!(request.is_lock(), true);
    assert_eq!(*request.btc_receiver(), btc_receiver);

    contract.set_redeem_status_to_executed(redeem_id);

    contract.burn_token(redeem_id);

    assert_eq!(contract.redeem_request(redeem_id).is_completed(), true);
    destroy(_lc);
    destroy(contract);
    scenario.end();
}
