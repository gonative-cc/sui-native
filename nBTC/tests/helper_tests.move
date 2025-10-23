#[test_only]
module nbtc::helper_tests;

use bitcoin_executor::sighash::create_segwit_preimage;
use nbtc::helper::compose_withdraw_unsign_tx;
use nbtc::nbtc_tests::setup;
use sui::test_utils::destroy;

const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";

#[test]
fun create_unsign_reedem_tx_happy_case() {
    let sender = @0x1;
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, sender);

    let outpoint = vector[];
    let receiver_spend_key = x"";
    let amount = 0;
    let fee = 0;
    let tx = compose_withdraw_unsign_tx(&ctr, outpoint, receiver_spend_key, amount, fee);

    let sign_hash = create_segwit_preimage(
        &tx,
        0, // input index
        &x"", // segwit nbtc spend key
        x"00000000", // amount
        0x01, // SIGNHASH_ALL
    );
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
