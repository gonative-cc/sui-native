#[test_only]
module nbtc::redeem_workflow_tests;

use nbtc::nbtc::NBTC;
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::new_utxo;
use sui::clock;
use sui::coin::mint_for_testing;
use sui::test_utils::destroy;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";
const ADMIN: address = @0xad;

#[test]
fun test_redeem_workflow_happy_case() {
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, ADMIN);

    let dwallet_id = object::id_from_address(ADMIN);
    ctr.add_utxo_for_test(
        0,
        new_utxo(
            x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6",
            1,
            2500,
            NBTC_SCRIPT_PUBKEY,
            dwallet_id,
        ),
    );

    let nbtc_coin = mint_for_testing<NBTC>(1000, scenario.ctx());
    let receiver_script = x"00140000000000000000000000000000000000000002";
    let mut clock = clock::create_for_testing(scenario.ctx());
    let redeem_id = ctr.redeem(nbtc_coin, receiver_script, scenario.ctx(), &clock);

    let request = ctr.redeem_request(redeem_id);
    assert!(request.status().is_resolving());

    let utxo_ids = vector[0];
    let dwallet_ids = vector[dwallet_id];
    ctr.propose_utxos(redeem_id, utxo_ids, dwallet_ids, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert!(request.status().is_resolving());
    assert!(request.inputs_length() == 1);

    let redeem_duration = ctr.redeem_duration();
    clock.increment_for_testing(redeem_duration + 1);

    ctr.finalize_redeem_request(redeem_id, &clock);

    let request = ctr.redeem_request(redeem_id);
    assert!(request.status().is_signing());

    clock.destroy_for_testing();
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
