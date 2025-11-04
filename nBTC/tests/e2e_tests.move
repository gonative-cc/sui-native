#[test_only]
module nbtc::e2e_tests;

use nbtc::nbtc::NBTC;
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::new_utxo;
use sui::coin::mint_for_testing;
use sui::test_scenario::{Self, take_from_address, Scenario};
use sui::test_utils::destroy;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";
#[test]
fun e2e_happy_case() {
    let admin = @0xad;
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, admin);

    ctr.add_utxo_for_test(
        0,
        new_utxo(x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6", 0, 1500),
    );
    let nbtc_coin = mint_for_testing<NBTC>(10, scenario.ctx());
    let receiver_spend_key = x"00140000000000000000000000000000000000000002";
    ctr.redeem(nbtc_coin, receiver_spend_key, scenario.ctx());

    destroy(lc);
    destroy(ctr);
    scenario.end();
}
