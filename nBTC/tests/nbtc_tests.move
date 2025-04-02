#[test_only]
module nbtc::nbtc_tests;

use nbtc::nbtc::{Self, WrappedTreasuryCap, EMintAmountIsZero, ETxAlreadyUsed, NBTC};
use bitcoin_spv::light_client::{new_light_client_with_params_without_share, LightClient};
use bitcoin_spv::params;
use sui::address;
use sui::coin::Coin;
use sui::test_scenario::{Self, take_from_address};

#[test_only]
fun new_lc_for_test(ctx: &mut TxContext) : LightClient {
    let start_block = 0;
    let headers = vector[
        x"00000020a97594d6b5b9369535da225d464bde7e0ae3794e9b270a010000000000000000879574acf5757cd2af60949ff20faddd581aaebc6d2327646cb84f0d11fc1cc2bb27e8585a330218b119eaee"
    ];
    let lc = new_light_client_with_params_without_share(params::mainnet(), start_block, headers, 0, 8, ctx);
    return lc
}

#[test_only]
fun init_nbtc(btc_treasury : vector<u8>, ctx: &mut TxContext): (LightClient, WrappedTreasuryCap) {
    let lc = new_lc_for_test(ctx);
    let lc_id = lc.client_id().uid_to_inner();
    let cap = nbtc::init_for_testing(lc_id, btc_treasury, ctx);
    (lc, cap)
}

#[test]
fun test_nbtc_mint() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    let btc_treasury = x"509a651dd392e1bc125323f629b67d65cca3d4bb";
    let (lc, mut cap) = init_nbtc(btc_treasury, ctx);
    let proof = vector[x"65dc93e9c743430f6218e367841b87efc14d773bb03268be49ad98b9c2f51ef6"];
    let version = x"01000000";
    let input_count = 1;
    let inputs = x"be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff";
    let output_count = 3;
    let outputs = x"00e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000226a20bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c";
    let lock_time = x"00000000";
    let height = 0;
    let tx_index = 1;
    let owner_address = address::from_bytes(x"bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c");
    nbtc::mint(&mut cap, &lc, version, input_count, inputs, output_count, outputs, lock_time, proof, height, tx_index, ctx);
    test_scenario::next_tx(&mut scenario, sender);
    let coin = take_from_address<Coin<NBTC>>(&scenario, owner_address);
    let value = coin.value();
    assert!(value == 100000000);
    sui::test_utils::destroy(coin);
    sui::test_utils::destroy(lc);
    sui::test_utils::destroy(cap);
    scenario.end();
}


#[test]
#[expected_failure(abort_code = EMintAmountIsZero)]
fun test_nbtc_mint_fail_amount_is_zero() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    let btc_treasury = x"509a651dd392e1bc125323f629b67d65cca3d4ff"; // modified address
    let (lc, mut cap) = init_nbtc(btc_treasury, ctx);
    let proof = vector[x"65dc93e9c743430f6218e367841b87efc14d773bb03268be49ad98b9c2f51ef6"];
    let version = x"01000000";
    let input_count = 1;
    let inputs = x"be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff";
    let output_count = 3;
    let outputs = x"00e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000226a20bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c";
    let lock_time = x"00000000";
    let height = 0;
    let tx_index = 1;
    nbtc::mint(&mut cap, &lc, version, input_count, inputs, output_count, outputs, lock_time, proof, height, tx_index, ctx);
    sui::test_utils::destroy(lc);
    sui::test_utils::destroy(cap);
    scenario.end();
}

#[test]
#[expected_failure(abort_code = ETxAlreadyUsed)]
fun test_nbtc_mint_fail_tx_already_used() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    let btc_treasury = x"509a651dd392e1bc125323f629b67d65cca3d4bb";
    let (lc, mut cap) = init_nbtc(btc_treasury, ctx);
    let proof = vector[x"65dc93e9c743430f6218e367841b87efc14d773bb03268be49ad98b9c2f51ef6"];
    let version = x"01000000";
    let input_count = 1;
    let inputs = x"be8c30f6aa0d64b956b0612d02ece4297e66e8f31983c9c224f3775d058334e5000000008a47304402206e2f7b781b1cb06caae6ee597fa04f6893bc2fd4f6708779a4adb2e45a543a7002204bf2bc170288dd7e37b3fb9bc53b44bb95ae4bf5eb8744c94605b2478dc6b3df014104d73f6e48dc738187df764f8f8c996ff44235e62a24ab0a4959b3d02e913d8e390f4d54f30e2ddb3992e5a25eda5594550321e61a6ad5bac1adcc7a5100827602ffffffff";
    let output_count = 3;
    let outputs = x"00e1f505000000001976a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac00e9a435000000001976a91451614157e1d735b7b65ad003cd4042ce501ede2388ac0000000000000000226a20bbad40ecca892cf0d54ba0b9c986454be0695ce29642223a02c37e3b87a4499c";
    let lock_time = x"00000000";
    let height = 0;
    let tx_index = 1;
    nbtc::mint(&mut cap, &lc, version, input_count, inputs, output_count, outputs, lock_time, proof, height, tx_index, ctx);
    // double spend
    nbtc::mint(&mut cap, &lc, version, input_count, inputs, output_count, outputs, lock_time, proof, height, tx_index, ctx);

    sui::test_utils::destroy(lc);
    sui::test_utils::destroy(cap);
    scenario.end();
}
