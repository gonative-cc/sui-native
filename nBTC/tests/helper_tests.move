#[test_only]
module nbtc::helper_tests;

use bitcoin_executor::interpreter::create_p2wpkh_scriptcode;
use bitcoin_executor::sighash::create_segwit_preimage;
use bitcoin_executor::utxo::{new_outpoint, new_data};
use bitcoin_parser::encoding::u64_to_le_bytes;
use bitcoin_parser::output;
use nbtc::helper::compose_withdraw_unsign_tx;
use nbtc::nbtc_tests::setup;
use std::unit_test::assert_eq;
use sui::test_utils::destroy;

#[test]
fun create_unsign_reedem_tx_happy_case() {
    let sender = @0x1;
    let nbtc_spend_key = x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb";
    let (lc, mut ctr, mut scenario) = setup(nbtc_spend_key, sender);

    let outpoint = vector[
        new_outpoint(x"c22646a7af0b3862c27dadab84cfb4a58dd9e1e4a417e7517bff7f05ae4c575e", 1),
        new_outpoint(x"2879c6bf4c92618ae198e516c9414629ad7499bd94fe71a3f1614b76ab4fe3c6", 0),
    ];

    ctr.set_utxo(
        outpoint[0],
        new_data(0, false, output::new(9979700, x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb")),
    );
    ctr.set_utxo(
        outpoint[1],
        new_data(0, false, output::new(10000000, x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb")),
    );
    let amount = 12000150;
    let fee = 150;
    let tx = compose_withdraw_unsign_tx(
        &ctr,
        outpoint,
        x"00149b622481f0407714dd3ef4850a02ffbdc19dfa96",
        amount,
        fee,
    );

    // script code from public key
    let script_code = create_p2wpkh_scriptcode(x"e8340a12dd2c95e5fedc8b088a81dcac42c106fb");
    let sign_hash = create_segwit_preimage(
        &tx,
        0, // input index
        &script_code, // segwit nbtc spend key
        u64_to_le_bytes(9979700), // amount
        0x01, // SIGNHASH_ALL
    );
    assert_eq!(
        std::hash::sha2_256(sign_hash),
        x"ea5ea540e3f9ba41ae92f25963a69528d4559d1a0b30015803c3dc27eb6a3bad",
    );
    // 725d8f518be05c56d6ac752092a92fa5d819c627e8a9df266dd2e351e246f023
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
