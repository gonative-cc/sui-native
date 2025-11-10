#[test_only]
module nbtc::redeem_request_tests;

use ika_dwallet_2pc_mpc::coordinator_inner::dwallet_cap_for_testing;
use nbtc::nbtc::{AdminCap, admin_cap_for_testing};
use nbtc::nbtc_tests::setup;
use nbtc::nbtc_utxo::{new_utxo, Utxo};
use std::unit_test::assert_eq;
use sui::test_utils::destroy;

#[test]
fun raw_withdraw_tx_signed_tests() {
    let ntc_spend_key = x"00145c2dc82f606be66506b7403f9b304f5e0908b652";
    let nbtc_pk = x"0329cdb63380e0a7109773703534659df6be41c48b4e80e5da77eb384ff7d41be2";
    let sender = @0x1;
    let (lc, mut ctr, mut scenario) = setup(ntc_spend_key, sender);

    scenario.next_tx(sender);

    let admin_cap = admin_cap_for_testing(scenario.ctx());
    // mock dwallet id
    let dwallet = object::new(scenario.ctx());
    let dwallet_id = dwallet.uid_to_inner();
    let dwallet_cap = dwallet_cap_for_testing(dwallet_id, scenario.ctx());

    admin_cap.add_dwallet_cap(&mut ctr, dwallet_cap, ntc_spend_key, nbtc_pk);
    let request_id = 0;
    let amount = 72561;
    let btc_receiver = x"001464f9139a4a853b3d5ad1315ceb707386ed343c2c";
    let spend_key = x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb";
    let utxos = vector[
        new_utxo(
            x"9dafd815a150414d02047a22ab806dbd2f43d0e1ea5922dadd5396f6d6776920",
            41,
            amount,
            spend_key,
        ),
    ];
    let signatures = vector[
        x"3044022063db5a24fec209152863fb251cc349a7030220bf4ca6e6296002d46d4c3651a502205a0b4b5a520fc42b91b8a888351c1c42bd2864aba2c398007405e957dea77bb101",
    ];
    let fee = 656;
    ctr.create_redeem_request_for_testing(
        request_id,
        sender,
        btc_receiver,
        amount,
        fee,
        utxos,
        signatures,
        scenario.ctx(),
    );

    let raw_tx = ctr.raw_signed_tx(request_id);

    // one output, no remains token
    assert_eq!(
        raw_tx,
        x"020000000001019dafd815a150414d02047a22ab806dbd2f43d0e1ea5922dadd5396f6d67769202900000000ffffffff01e11801000000000016001464f9139a4a853b3d5ad1315ceb707386ed343c2c02473044022063db5a24fec209152863fb251cc349a7030220bf4ca6e6296002d46d4c3651a502205a0b4b5a520fc42b91b8a888351c1c42bd2864aba2c398007405e957dea77bb101210329cdb63380e0a7109773703534659df6be41c48b4e80e5da77eb384ff7d41be200000000",
    );
    destroy(lc);
    destroy(ctr);
    destroy(dwallet);
    destroy(admin_cap);
    scenario.end();
}
