// SPDX-License-Identifier: MPL-2.0

#[test_only]
module nbtc::nbtc_tests;

use bitcoin_lib::header;
use bitcoin_spv::light_client::{new_light_client, LightClient};
use ika_dwallet_2pc_mpc::coordinator_inner::dwallet_cap_for_testing;
use nbtc::nbtc::{Self, NbtcContract, EMintAmountIsZero, ETxAlreadyUsed, EAlreadyUpdated, NBTC};
use std::unit_test::assert_eq;
use sui::address;
use sui::coin::Coin;
use sui::test_scenario::{Self, take_from_address, Scenario};
use sui::test_utils::destroy;

// The fallback Sui address to receive nBTC if OP_RETURN data is invalid or missing.
// Use for test
const FALLBACK_ADDR: address = @0xB0B;
const NBTC_SCRIPT_PUBKEY: vector<u8> = x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac";

// copy from nbtc.move
const MINT_OP_APPLY_FEE: u32 = 1;

// context for this test:
// regtest network
// 1 block
// 2 transaction = [6c9fb0ef6ca1661415c0a7cd86bcc8f9c6df1936f1e44375a53838604a35ee52,a6f3ad0110796ebafce9e810d831d2df123d86edebaccdb61b8511d57f67ce06] // big endian order
// first transaction raw = 0100000001be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff0300e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000036a010100000000 // fallback
// second transaction raw = 0100000001be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff0300e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000236a2100bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c00000000 // flag 00

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
    ctr: &mut NbtcContract,
    lc: &LightClient,
    data: TestData,
    sender: address,
    ops_arg: u32,
) {
    let TestData { tx_bytes, proof, height, tx_index, expected_recipient, expected_amount } = data;
    ctr.mint(lc, tx_bytes, proof, height, tx_index, vector[], ops_arg, scenario.ctx());
    test_scenario::next_tx(scenario, sender);

    let coin = take_from_address<Coin<NBTC>>(scenario, expected_recipient);
    let amount = coin.value();
    if (ops_arg == MINT_OP_APPLY_FEE) assert_eq!(amount, expected_amount - ctr.get_mint_fee())
    else assert_eq!(amount, expected_amount);
    destroy(coin);
}

#[test_only]
fun get_valid_mint_data(): TestData {
    TestData {
        tx_bytes: x"0100000001be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff0300e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000236a2100bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c00000000", // tx_2
        proof: vector[x"3a48fd8cbd8893bffadf83e563a3958a77ef94ec1c7dc827edf14ad4d53c0436"], // pre-image: single sha256 over the tx_1
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
        tx_bytes: x"0100000001be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff0300e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000036a010100000000", // tx_1
        proof: vector[x"514956dad9c4d52fbdb3ae846646d1ad1ba34587dee9c82a291447a9f9909061"], // pre-image: single sha256 over the tx_2
        height: 0,
        tx_index: 0,
        expected_recipient: FALLBACK_ADDR,
        expected_amount: 100_000_000,
    }
}

#[test_only]
public fun setup(
    nbtc_bitcoin_addr: vector<u8>,
    sender: address,
): (LightClient, NbtcContract, Scenario) {
    let mut scenario = test_scenario::begin(sender);

    let headers = vector[
        header::new(
            x"00000020a97594d6b5b9369535da225d464bde7e0ae3794e9b270a010000000000000000addcae45a90f73dc68e3225b2d0be1c155bf9b0864f187e31203079c0b6d42c5bb27e8585a330218b119eaee",
        ),
    ];

    let lc = new_light_client(bitcoin_spv::params::regtest(), 0, headers, 0, 1, scenario.ctx());
    let mut ctr = nbtc::init_for_testing(
        lc.client_id().to_address(),
        FALLBACK_ADDR,
        nbtc_bitcoin_addr,
        scenario.ctx(),
    );
    ctr.set_dwallet_cap_for_test(
        nbtc_bitcoin_addr,
        nbtc_bitcoin_addr,
        dwallet_cap_for_testing(object::id_from_address(@0x01), scenario.ctx()),
        scenario.ctx(),
    );
    (lc, ctr, scenario)
}

#[test]
fun test_nbtc_mint() {
    let sender = @0x1;
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, sender);

    mint_and_assert(
        &mut scenario,
        &mut ctr,
        &lc,
        get_valid_mint_data(),
        sender,
        0,
    );

    // check with fallback
    mint_and_assert(
        &mut scenario,
        &mut ctr,
        &lc,
        get_fallback_mint_data(),
        sender,
        0,
    );

    let balance = ctr.active_balance();
    let total_amount_expected = 2 * get_valid_mint_data().expected_amount;
    assert_eq!(balance, total_amount_expected);
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
fun test_mint_with_fee() {
    let sender = @0x1;
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, sender);

    mint_and_assert(
        &mut scenario,
        &mut ctr,
        &lc,
        get_valid_mint_data(),
        sender,
        1,
    );

    // check with fallback
    mint_and_assert(
        &mut scenario,
        &mut ctr,
        &lc,
        get_fallback_mint_data(),
        sender,
        1,
    );

    // mint with fallback should take fee as well.
    assert_eq!(ctr.get_fees_collected(), 2*ctr.get_mint_fee());
    let total_amount = ctr.active_balance();
    let total_amount_expected =
        get_fallback_mint_data().expected_amount +
    get_valid_mint_data().expected_amount;
    assert_eq!(total_amount, total_amount_expected);
    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
#[expected_failure(abort_code = EMintAmountIsZero)]
fun test_nbtc_mint_fail_amount_is_zero() {
    let sender = @0x1;
    // Use a different treasury address so the payment to our main treasury is not found.
    let (lc, mut ctr, mut scenario) = setup(
        x"76a914509a651dd392e1bc125323f629b67d65cca3d4ff88ac",
        sender,
    );
    let data = get_valid_mint_data();

    ctr.mint(
        &lc,
        data.tx_bytes,
        data.proof,
        data.height,
        data.tx_index,
        vector[],
        0,
        scenario.ctx(),
    );

    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test]
#[expected_failure(abort_code = ETxAlreadyUsed)]
fun test_nbtc_mint_fail_tx_already_used() {
    let sender = @0x1;
    let (lc, mut ctr, mut scenario) = setup(NBTC_SCRIPT_PUBKEY, sender);
    let data = get_valid_mint_data();

    // First mint, should succeed
    ctr.mint(
        &lc,
        data.tx_bytes,
        data.proof,
        data.height,
        data.tx_index,
        vector[],
        0,
        scenario.ctx(),
    );

    // Second mint (double spend), should fail
    ctr.mint(
        &lc,
        data.tx_bytes,
        data.proof,
        data.height,
        data.tx_index,
        vector[],
        0,
        scenario.ctx(),
    );

    destroy(lc);
    destroy(ctr);
    scenario.end();
}

#[test, expected_failure(abort_code = EAlreadyUpdated)]
fun test_update_version_fail() {
    let sender = @0x01;
    let (_lc, mut ctr, _scenario) = setup(NBTC_SCRIPT_PUBKEY, sender);
    nbtc::update_version(&mut ctr);
    abort
}
