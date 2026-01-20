#[test_only]
module nbtc::redeem_request_tests;

use ika_dwallet_2pc_mpc::coordinator_inner::dwallet_cap_for_testing;
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::new_utxo;
use nbtc::redeem_request;
use nbtc::storage;
use nbtc::test_constants::MOCK_DWALLET_ID;
use std::unit_test::{assert_eq, destroy};
use sui::clock;

#[test]
fun raw_withdraw_tx_signed_tests() {
    let nbtc_spend_key = x"51200f0c8db753acbd17343a39c2f3f4e35e4be6da749f9e35137ab220e7b238a667";
    let sender = @0x1;
    let (lc, ctr, _dwallet_coordinator, mut scenario) = setup(
        nbtc_spend_key,
        sender,
        MOCK_DWALLET_ID!(),
    );

    scenario.next_tx(sender);

    let amount = 72561;
    let btc_receiver = x"001464f9139a4a853b3d5ad1315ceb707386ed343c2c";
    let utxos = vector[
        new_utxo(
            x"9dafd815a150414d02047a22ab806dbd2f43d0e1ea5922dadd5396f6d6776920",
            41,
            amount,
            MOCK_DWALLET_ID!(),
        ),
    ];

    let signatures = vector[
        x"b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae",
    ];
    let fee = 656;
    let clock = clock::create_for_testing(scenario.ctx());
    let mut r = redeem_request::new(
        nbtc_spend_key,
        sender,
        btc_receiver,
        amount,
        fee,
        clock.timestamp_ms(),
        scenario.ctx(),
    );
    let mut btc_store = storage::create_storage(scenario.ctx());
    btc_store.add_dwallet(
        storage::create_dwallet(
            dwallet_cap_for_testing(MOCK_DWALLET_ID!(), scenario.ctx()),
            nbtc_spend_key,
            vector::empty(),
            scenario.ctx(),
        ),
    );

    let utxo_store = btc_store.utxo_store_mut();
    utxos.destroy!(|utxo| {
        utxo_store.add(utxo);
    });

    r.update_to_signing_for_test(vector[0]);
    r.move_to_signing_status(0, &mut btc_store);
    r.update_to_signed_for_test(signatures);

    let tx = r.compose_tx(&btc_store);
    let outputs = tx.outputs();
    assert_eq!(outputs.length(), 1);
    assert_eq!(tx.tx_id(), x"c148c42fbc5d424a9cce3518f678e86086d801bcd05bff10542fb52c1f09db4e");
    // one output, no remains token
    assert_eq!(
        tx.serialize_segwit(),
        x"020000000001019dafd815a150414d02047a22ab806dbd2f43d0e1ea5922dadd5396f6d67769202900000000ffffffff01e11801000000000016001464f9139a4a853b3d5ad1315ceb707386ed343c2c0140b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae00000000",
    );
    destroy(lc);
    destroy(ctr);
    destroy(r);
    destroy(btc_store);
    destroy(_dwallet_coordinator);
    clock.destroy_for_testing();
    scenario.end();
}
