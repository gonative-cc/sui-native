#[test_only]
module nbtc::e2e_tests;

use nbtc::nbtc_tests::setup;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";
#[test]
fun e2e_happy_case() {
    let sender = @0x01;
    let (lc, ctr, scenario) = setup(NBTC_SCRIPT_PUBKEY, sender);
    ctr.add_utxo_for_test();
}
