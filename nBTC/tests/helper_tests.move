#[test_only]
module nbtc::helper_tests;

use bitcoin_executor::interpreter::create_p2wpkh_scriptcode;
use bitcoin_executor::sighash::create_segwit_preimage;
use bitcoin_parser::encoding::u64_to_le_bytes;
use nbtc::helper::compose_withdraw_tx;
use nbtc::nbtc::new_utxo;
use nbtc::nbtc_tests::setup;
use std::unit_test::assert_eq;
use sui::test_utils::destroy;

#[test]
fun create_unsign_reedem_tx_happy_case() {
    let sender = @0x1;
    let nbtc_spend_key = x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb";
    let (lc, ctr, scenario) = setup(nbtc_spend_key, sender);

    let utxos = vector[
        new_utxo(x"c22646a7af0b3862c27dadab84cfb4a58dd9e1e4a417e7517bff7f05ae4c575e", 1, 9979700),
        new_utxo(x"2879c6bf4c92618ae198e516c9414629ad7499bd94fe71a3f1614b76ab4fe3c6", 0, 10000000),
    ];

    let amount = 12000150;
    let fee = 150;
    let tx = compose_withdraw_tx(
        &ctr,
        utxos,
        x"00149b622481f0407714dd3ef4850a02ffbdc19dfa96",
        amount,
        fee,
    );

    // script code from public key
    let script_code = create_p2wpkh_scriptcode(x"e8340a12dd2c95e5fedc8b088a81dcac42c106fb");
    let sign_hashes = vector[
        x"ea5ea540e3f9ba41ae92f25963a69528d4559d1a0b30015803c3dc27eb6a3bad",
        x"725d8f518be05c56d6ac752092a92fa5d819c627e8a9df266dd2e351e246f023",
    ];

    tx.inputs().length().do!(|i| {
        let sign_hash = create_segwit_preimage(
            &tx,
            i, // input index
            &script_code, // segwit nbtc spend key
            u64_to_le_bytes(utxos[i].value()), // amount
            0x01, // SIGNHASH_ALL
        );
        assert_eq!(std::hash::sha2_256(sign_hash), sign_hashes[i]);
    });
    //
    destroy(lc);
    destroy(ctr);
    scenario.end();
}
