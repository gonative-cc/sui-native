// SPDX-License-Identifier: MPL-2.0

#[test_only]
module nbtc::nbtc_tests;

use bitcoin_spv::light_client::{new_light_client, LightClient};
use bitcoin_spv::block_header::new_block_header;

use nbtc::nbtc::{
    Self,
    WrappedTreasuryCap,
    EMintAmountIsZero,
    ETxAlreadyUsed,
    EAlreadyUpdated,
    NBTC
};
use std::unit_test::assert_eq;
use sui::address;
use sui::coin::Coin;
use sui::test_scenario::{Self, take_from_address, Scenario};
use sui::test_utils::destroy;

// The fallback Sui address to receive nBTC if OP_RETURN data is invalid or missing.
// Use for test
const FALLBACK_ADDR: address = @0xB0B;
const BTC_TREASURY: vector<u8> = x"509a651dd392e1bc125323f629b67d65cca3d4bb";

// context for this test:
// regtest network
// 1 block
// 2 transaction = [6c9fb0ef6ca1661415c0a7cd86bcc8f9c6df1936f1e44375a53838604a35ee52, ab427a92149a1a5a2d9d2b6db3db0c81a32ce38996672f3372cc8b16bb706a17] // big endian order
// first transaction raw = 0100000001be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff0300e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000036a010100000000
// second transaction raw = 0100000001be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff0300e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000226a20bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c00000000

#[test_only]
public struct TestData has drop {
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    expected_recipient: address,
    expected_amount: u64,
}

#[test_only]
fun mint_and_assert(
    scenario: &mut Scenario,
    cap: &mut WrappedTreasuryCap,
    lc: &LightClient,
    data: TestData,
    sender: address,
) {
    let TestData { tx_bytes, proof, height, tx_index, expected_recipient, expected_amount } = data;

    nbtc::mint(cap, lc, tx_bytes, proof, height, tx_index, scenario.ctx());
    test_scenario::next_tx(scenario, sender);

    let coin = take_from_address<Coin<NBTC>>(scenario, expected_recipient);
    assert_eq!(coin.value(), expected_amount);
    destroy(coin);
}

#[test_only]
fun get_valid_mint_data(): TestData {
    TestData {
        tx_bytes: x"0100000001be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff0300e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000226a20bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c00000000", // tx_1
        proof: vector[x"3a48fd8cbd8893bffadf83e563a3958a77ef94ec1c7dc827edf14ad4d53c0436"], // pre-image: single sha256 over the tx_2
        height: 0,
        tx_index: 1,
        expected_recipient: address::from_bytes(
            x"bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c",
        ),
        expected_amount: 100_000_000,
    }
}

#[test_only]
fun get_fallback_mint_data(): TestData {
    TestData {
        tx_bytes: x"0100000001be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff0300e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000036a010100000000", // tx_2
        proof: vector[x"93af98fe3fec5515f33faf23a3fce63134f1a3fb25dcc92ef8216a4d5f4c2727"], // pre-image: single sha256 over the tx_1
        height: 0,
        tx_index: 0,
        expected_recipient: FALLBACK_ADDR,
        expected_amount: 100_000_000,
    }
}

#[test_only]
fun setup(btc_treasury: vector<u8>, sender: address): (LightClient, WrappedTreasuryCap, Scenario) {
    let mut scenario = test_scenario::begin(sender);

    let headers = vector[
        new_block_header(x"00000020a97594d6b5b9369535da225d464bde7e0ae3794e9b270a010000000000000000234edbf5d62a2790addd8d3fc85727c58c301ddbdebd2738c8f72fb6427ce722bb27e8585a330218b119eaee"),
    ];

    let lc = new_light_client(bitcoin_spv::params::regtest(), 0, headers, 0, 0, scenario.ctx());

    let mut cap = nbtc::init_for_testing(scenario.ctx());
    cap.setup(lc.client_id().to_address(), FALLBACK_ADDR, btc_treasury);
    (lc, cap, scenario)
}

#[test]
fun test_nbtc_mint() {
    let sender = @0x1;
    let (lc, mut cap, mut scenario) = setup(BTC_TREASURY, sender);

    mint_and_assert(
        &mut scenario,
        &mut cap,
        &lc,
        get_valid_mint_data(),
        sender,
    );

    destroy(lc);
    destroy(cap);
    scenario.end();
}

#[test]
fun test_nbtc_mint_fallback() {
    let sender = @0x1;
    let (lc, mut cap, mut scenario) = setup(BTC_TREASURY, sender);

    mint_and_assert(
        &mut scenario,
        &mut cap,
        &lc,
        get_fallback_mint_data(),
        sender,
    );

    destroy(lc);
    destroy(cap);
    scenario.end();
}

#[test]
#[expected_failure(abort_code = EMintAmountIsZero)]
fun test_nbtc_mint_fail_amount_is_zero() {
    let sender = @0x1;
    // Use a different treasury address so the payment to our main treasury is not found.
    let (lc, mut cap, mut scenario) = setup(x"509a651dd392e1bc125323f629b67d65cca3d4ff", sender);
    let data = get_valid_mint_data();

    nbtc::mint(
        &mut cap,
        &lc,
        data.tx_bytes,
        data.proof,
        data.height,
        data.tx_index,
        scenario.ctx(),
    );

    destroy(lc);
    destroy(cap);
    scenario.end();
}

#[test]
#[expected_failure(abort_code = ETxAlreadyUsed)]
fun test_nbtc_mint_fail_tx_already_used() {
    let sender = @0x1;
    let (lc, mut cap, mut scenario) = setup(BTC_TREASURY, sender);
    let data = get_valid_mint_data();

    // First mint, should succeed
    nbtc::mint(
        &mut cap,
        &lc,
        data.tx_bytes,
        data.proof,
        data.height,
        data.tx_index,
        scenario.ctx(),
    );

    // Second mint (double spend), should fail
    nbtc::mint(
        &mut cap,
        &lc,
        data.tx_bytes,
        data.proof,
        data.height,
        data.tx_index,
        scenario.ctx(),
    );

    destroy(lc);
    destroy(cap);
    scenario.end();
}

#[test, expected_failure(abort_code = EAlreadyUpdated)]
fun test_update_version_fail() {
    let sender = @0x01;
    let (_lc, mut cap, _scenario) = setup(BTC_TREASURY, sender);
    nbtc::update_version(&mut cap);
    abort
}

#[test, expected_failure(abort_code = nbtc::EReSetupTreasuryNotAllow)]
fun test_re_setup_treasury_should_fail() {
    let sender = @0x01;
    let (lc, mut cap, _scenario) = setup(BTC_TREASURY, sender);
    // resetup, should fail
    cap.setup(lc.client_id().to_address(), FALLBACK_ADDR, BTC_TREASURY);

    abort
}
