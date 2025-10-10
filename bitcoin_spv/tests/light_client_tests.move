// SPDX-License-Identifier: MPL-2.0

#[test_only]
module bitcoin_spv::light_client_tests;

use bitcoin_parser::header;
use bitcoin_spv::light_block::new_light_block;
use bitcoin_spv::light_client::{
    insert_header,
    new_light_client,
    initialize_light_client,
    update_version,
    LightClient,
    EWrongParentBlock,
    EDifficultyNotMatch,
    ETimeTooOld,
    EInvalidStartHeight,
    EAlreadyUpdated
};
use bitcoin_spv::params;
use std::unit_test::{assert_eq, assert_ref_eq};
use sui::test_scenario;

#[test_only]
fun new_lc_for_test(ctx: &mut TxContext): LightClient {
    let start_block = 858806;
    let raw_headers = vector[
        // {
        //     "version": "00a0b434",
        //     "previous_block_hash": "e99097082da749068bd8cc81f7ddd017f3153e1f25b000000000000000000000",
        //     "merkle_root": "fbef99870f826601fed79703773deb9122f03b5167c0b7554c00112f9fa99e17",
        //     "timestamp": "1320cf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "5c560dcc"
        // }
        x"00a0b434e99097082da749068bd8cc81f7ddd017f3153e1f25b000000000000000000000fbef99870f826601fed79703773deb9122f03b5167c0b7554c00112f9fa99e171320cf66763d03175c560dcc",
        // {
        //     "version": "00205223",
        //     "previous_block_hash": "ce8791e22d0a1b64cfb0b485af2ddba566cb54292e0c03000000000000000000",
        //     "merkle_root": "3f5d648740a3a0519c56fce7f230d4c35aa83c9df0478b77be3fc89f0acfb8cc",
        //     "timestamp": "9524cf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "1746f213"
        // }
        x"00205223ce8791e22d0a1b64cfb0b485af2ddba566cb54292e0c030000000000000000003f5d648740a3a0519c56fce7f230d4c35aa83c9df0478b77be3fc89f0acfb8cc9524cf66763d03171746f213",
        // {
        //     "version": "0000c723",
        //     "previous_block_hash": "67c8c7e8515c552d74707468a84d2fda2da63d65cbec01000000000000000000",
        //     "merkle_root": "ec9d236ac946e604e3272ab775a501ebe05e8b06a8ec70b8c51b7ccba38af21b",
        //     "timestamp": "1c26cf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "c3442435"
        // }
        x"0000c72367c8c7e8515c552d74707468a84d2fda2da63d65cbec01000000000000000000ec9d236ac946e604e3272ab775a501ebe05e8b06a8ec70b8c51b7ccba38af21b1c26cf66763d0317c3442435",
        // {
        //     "version": "00c05725",
        //     "previous_block_hash": "1d6ff0cb1d8eb9452f6578fafd41c5435dbfae6dbd5a01000000000000000000",
        //     "merkle_root": "a8c4158d905a4fd766328c4717222737d4105220ee3aae80fbe57928689a7544",
        //     "timestamp": "cb27cf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "a29c9617"
        // }
        x"00c057251d6ff0cb1d8eb9452f6578fafd41c5435dbfae6dbd5a01000000000000000000a8c4158d905a4fd766328c4717222737d4105220ee3aae80fbe57928689a7544cb27cf66763d0317a29c9617",
        // {
        //     "version": "00800a20",
        //     "previous_block_hash": "88931286b1c6af1e23730089387def8a89e248de2a6501000000000000000000",
        //     "merkle_root": "a6d9635ee5e71023ee76c5569e770d432302593757a0e2e343f083764cd8f315",
        //     "timestamp": "5328cf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "5a15982c"
        // }
        x"00800a2088931286b1c6af1e23730089387def8a89e248de2a6501000000000000000000a6d9635ee5e71023ee76c5569e770d432302593757a0e2e343f083764cd8f3155328cf66763d03175a15982c",
        // {
        //     "version": "00a06b23",
        //     "previous_block_hash": "d73ad1793c6b81cb331b00023a1c84611ae6fe46b08f00000000000000000000",
        //     "merkle_root": "dd4c22396df46efc796ebbdfd82cb74d4c3eaf5e8e18134b7fda9379e82ebd2a",
        //     "timestamp": "752bcf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "66c189d5"
        // }
        x"00a06b23d73ad1793c6b81cb331b00023a1c84611ae6fe46b08f00000000000000000000dd4c22396df46efc796ebbdfd82cb74d4c3eaf5e8e18134b7fda9379e82ebd2a752bcf66763d031766c189d5",
        // {
        //     "version": "00e06c2e",
        //     "previous_block_hash": "314994230081f451d0fba9016cea4be4afd3b4c20d4601000000000000000000",
        //     "merkle_root": "6e110e2bc3bb80af0fa41dada4829fe5bc8a7a6269b588fff5f708d551130d64",
        //     "timestamp": "9d2bcf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "c530dcc8"
        // }
        x"00e06c2e314994230081f451d0fba9016cea4be4afd3b4c20d46010000000000000000006e110e2bc3bb80af0fa41dada4829fe5bc8a7a6269b588fff5f708d551130d649d2bcf66763d0317c530dcc8",
        // {
        //     "version": "00000028",
        //     "previous_block_hash": "f1b88a82b706583e794319f23feb40ef6d9b42ee981702000000000000000000",
        //     "merkle_root": "3a899be6d63b05795d9b5da4d091fb9e37a5bf4783faaf1ae9e8aafa861462e7",
        //     "timestamp": "682dcf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "844b2ed2"
        // }
        x"00000028f1b88a82b706583e794319f23feb40ef6d9b42ee9817020000000000000000003a899be6d63b05795d9b5da4d091fb9e37a5bf4783faaf1ae9e8aafa861462e7682dcf66763d0317844b2ed2",
        // {
        //     "version": "00007f30",
        //     "previous_block_hash": "0670de9a5071f41ff3efdfede97d98b9044d71d77dd700000000000000000000",
        //     "merkle_root": "835f42b3d177c5d7b5b844efa4a6ac682bacc4d2862169ee8607da3ec5f4ef3a",
        //     "timestamp": "b32dcf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "59921deb"
        // }
        x"00007f300670de9a5071f41ff3efdfede97d98b9044d71d77dd700000000000000000000835f42b3d177c5d7b5b844efa4a6ac682bacc4d2862169ee8607da3ec5f4ef3ab32dcf66763d031759921deb",
        // {
        //     "version": "00800120",
        //     "previous_block_hash": "451bed6d330bd942a708b0858fdbb7d265e5b7caa3c000000000000000000000",
        //     "merkle_root": "25ba876f2efbd1522e36a7cd807879eeec843f95da8a01993556100e3226900b",
        //     "timestamp": "8d30cf66",
        //     "difficulty_target": "763d0317",
        //     "nonce": "bd91acc5"
        // }
        x"00800120451bed6d330bd942a708b0858fdbb7d265e5b7caa3c00000000000000000000025ba876f2efbd1522e36a7cd807879eeec843f95da8a01993556100e3226900b8d30cf66763d0317bd91acc5",
        // {
        //     "version": "0060b032",
        //     "previous_block_hash": "9fd61df7a284ba2f7debbfaef9c5152271ef8165037300000000000000000000",
        //     "merkle_root": "562139850fcfc2eb3204b1e790005aaba44e63a2633252fdbced58d2a9a87e2c",
        //     "timestamp": "db34cf66",
        //     "difficulty_target": "5b250317",
        //     "nonce": "245ddc6a"
        // }
        x"0060b0329fd61df7a284ba2f7debbfaef9c5152271ef8165037300000000000000000000562139850fcfc2eb3204b1e790005aaba44e63a2633252fdbced58d2a9a87e2cdb34cf665b250317245ddc6a",
    ];
    let headers = raw_headers.map!(|h| header::new(h));
    new_light_client(params::mainnet(), start_block, headers, 0, 8, ctx)
}

#[test, expected_failure(abort_code = EInvalidStartHeight)]
fun init_light_client_wrong_start_height_should_fail() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    // only the height is important in this case.
    let height = 2;
    let raw_headers = vector[
        x"00a0b434e99097082da749068bd8cc81f7ddd017f3153e1f25b000000000000000000000fbef99870f826601fed79703773deb9122f03b5167c0b7554c00112f9fa99e171320cf66763d03175c560dcc",
        x"00205223ce8791e22d0a1b64cfb0b485af2ddba566cb54292e0c030000000000000000003f5d648740a3a0519c56fce7f230d4c35aa83c9df0478b77be3fc89f0acfb8cc9524cf66763d03171746f213",
    ];
    let headers = raw_headers.map!(|h| header::new(h));

    initialize_light_client(0, height, headers, 0, 8, ctx);
    scenario.end();
}

#[test]
fun init_light_client_happy_case() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    let height = 2016;
    // only the height is important in this case.
    let raw_headers = vector[
        x"00a0b434e99097082da749068bd8cc81f7ddd017f3153e1f25b000000000000000000000fbef99870f826601fed79703773deb9122f03b5167c0b7554c00112f9fa99e171320cf66763d03175c560dcc",
        x"00205223ce8791e22d0a1b64cfb0b485af2ddba566cb54292e0c030000000000000000003f5d648740a3a0519c56fce7f230d4c35aa83c9df0478b77be3fc89f0acfb8cc9524cf66763d03171746f213",
    ];
    let headers = raw_headers.map!(|h| header::new(h));
    initialize_light_client(0, height, headers, 0, 8, ctx);
    scenario.end();
}

#[test]
fun test_set_get_block_happy_case() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    let lc = new_lc_for_test(ctx);
    // {
    //     "version": "0060b032",
    //     "previous_block_hash": "9fd61df7a284ba2f7debbfaef9c5152271ef8165037300000000000000000000",
    //     "merkle_root": "562139850fcfc2eb3204b1e790005aaba44e63a2633252fdbced58d2a9a87e2c",
    //     "timestamp": "db34cf66",
    //     "difficulty_target": "5b250317",
    //     "nonce": "245ddc6a"
    // }
    let header = header::new(
        x"0060b0329fd61df7a284ba2f7debbfaef9c5152271ef8165037300000000000000000000562139850fcfc2eb3204b1e790005aaba44e63a2633252fdbced58d2a9a87e2cdb34cf665b250317245ddc6a",
    );
    assert_eq!(lc.head_height(), 858816);
    assert_eq!(lc.head().header().block_hash(), header.block_hash());
    sui::test_utils::destroy(lc);
    scenario.end();
}

#[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
fun set_get_block_doesnot_exist_should_fail() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    let lc = new_lc_for_test(ctx);

    lc.get_light_block_by_hash(x"011011");

    sui::test_utils::destroy(lc);
    scenario.end();
}

#[test]
fun insert_header_happy_cases() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);

    let ctx = scenario.ctx();
    let mut lc = new_lc_for_test(ctx);
    // {
    //     "version": "00801e31",
    //     "previous_block_hash": "c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000000",
    //     "merkle_root": "530e6745eca48e937428b0f15669efdce807a071703ed5a4df0e85a3f6cc0f60",
    //     "timestamp": "1c35cf66",
    //     "difficulty_target": "5b250317",
    //     "nonce": "80f1e351"
    // }
    let headers = vector[
        header::new(
            x"00801e31c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000000530e6745eca48e937428b0f15669efdce807a071703ed5a4df0e85a3f6cc0f601c35cf665b25031780f1e351",
        ),
    ];

    lc.insert_headers(headers);
    let head_block = lc.get_light_block_by_hash(lc.head_hash()).header();

    assert_eq!(head_block.block_hash(), headers[0].block_hash());
    assert_ref_eq!(head_block, lc.head().header());
    // {
    //     "version": "0040a320",
    //     "previous_block_hash": "aa52a8971f61e56bf5a45117e3e224eabfef9237cb9a01000000000000000000",
    //     "merkle_root": "60a9a5edd4e39b70ee803e3d22673799ae6ec733ea7549442324f9e3a790e4e4",
    //     "timestamp": "b806e166",
    //     "difficulty_target": "5b250317",
    //     "nonce": "807427ca"
    // }
    let last_block_header = header::new(
        x"0040a320aa52a8971f61e56bf5a45117e3e224eabfef9237cb9a0100000000000000000060a9a5edd4e39b70ee803e3d22673799ae6ec733ea7549442324f9e3a790e4e4b806e1665b250317807427ca",
    );
    let last_block = new_light_block(
        860831,
        last_block_header,
        0,
    );

    lc.append_block(last_block);
    // {
    //     "version": "00608923",
    //     "previous_block_hash": "9c7c45da6d872c93dc9e8389d52b04bdd0a824eb308002000000000000000000",
    //     "merkle_root": "fb4c3ac894ebc99c7a7b76ded35ec1c719907320ab781689ba1dedca40c5a9d7",
    //     "timestamp": "c50de166",
    //     "difficulty_target": "8c090317",
    //     "nonce": "16c80c0d"
    // }
    let headers = vector[
        header::new(
            x"006089239c7c45da6d872c93dc9e8389d52b04bdd0a824eb308002000000000000000000fb4c3ac894ebc99c7a7b76ded35ec1c719907320ab781689ba1dedca40c5a9d7c50de1668c09031716c80c0d",
        ),
    ];

    lc.insert_headers(headers);
    assert_eq!(*lc.head().header(), headers[0]);
    sui::test_utils::destroy(lc);
    scenario.end();
}

// Test case: chain=[X, Y, Z], inserting [A, A], where A.parent()=Z. It should fail, because it
// doesn't create a chain, but a tree under node Z:
// X-Y-Z-A
//     \-A
#[test, expected_failure(abort_code = EWrongParentBlock)]
fun insert_headers_that_dont_from_a_chain_should_fail() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);

    let ctx = scenario.ctx();
    let mut lc = new_lc_for_test(ctx);
    // {
    //     "version": "00801e31",
    //     "previous_block_hash": "c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000000",
    //     "merkle_root": "530e6745eca48e937428b0f15669efdce807a071703ed5a4df0e85a3f6cc0f60",
    //     "timestamp": "1c35cf66",
    //     "difficulty_target": "5b250317",
    //     "nonce": "80f1e351"
    // }
    let h = header::new(
        x"00801e31c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000000530e6745eca48e937428b0f15669efdce807a071703ed5a4df0e85a3f6cc0f601c35cf665b25031780f1e351",
    );
    // we insert 2 identical headers.
    let headers = vector[h, h];
    lc.insert_headers(headers);
    abort
}

#[test, expected_failure(abort_code = EWrongParentBlock)]
fun insert_header_block_hash_not_match_should_fail() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let mut lc = new_lc_for_test(scenario.ctx());
    // we changed the previous block hash to make the new header's previous hash not match with last hash
    // from: c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000000
    // to:   c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000001
    let new_header = header::new(
        x"00801e31c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000001530e6745eca48e937428b0f15669efdce807a071703ed5a4df0e85a3f6cc0f601c35cf665b25031780f1e351",
    );
    let h = *lc.head();
    lc.insert_header(&h, new_header);
    abort
}

#[test, expected_failure(abort_code = EDifficultyNotMatch)]
fun insert_header_failed_difficulty_not_match_should_fail() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let mut lc = new_lc_for_test(scenario.ctx());
    // we changed the difficulty to make the new header's previous hash not match with last hash
    // from 5b250317 to 5b250318
    let new_header = header::new(
        x"00801e31c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000000530e6745eca48e937428b0f15669efdce807a071703ed5a4df0e85a3f6cc0f601c35cf665b25031880f1e351",
    );
    let h = *lc.head();
    lc.insert_header(&h, new_header);
    abort
}

#[test, expected_failure(abort_code = ETimeTooOld)]
fun insert_header_failed_timestamp_too_old_should_fail() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let mut lc = new_lc_for_test(scenario.ctx());
    // we changed timestamp from 1c35cf66 to 0c35cf46
    let new_header = header::new(
        x"00801e31c24ae25304cbac7c3d3b076e241abb20ff2da1d3ddfc00000000000000000000530e6745eca48e937428b0f15669efdce807a071703ed5a4df0e85a3f6cc0f600c35cf465b25031780f1e351",
    );
    let h = *lc.head();
    lc.insert_header(&h, new_header);
    abort
}

#[test, expected_failure(abort_code = EAlreadyUpdated)]
fun test_update_version_fail() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let mut lc = new_lc_for_test(scenario.ctx());
    update_version(&mut lc);
    abort
}

#[test]
fun test_verify_blocks() {
    let sender = @0x01;
    let mut scenario = test_scenario::begin(sender);
    let ctx = scenario.ctx();
    let lc = new_lc_for_test(ctx);
    let valid_hash = x"67c8c7e8515c552d74707468a84d2fda2da63d65cbec01000000000000000000";
    let invalid_hash = x"0d6ff0cb1d8eb9452f6578fafd41c5435dbfae6dbd5a01000000000000000000";
    let expected_results = vector[true, false];
    assert_eq!(lc.verify_blocks(vector[valid_hash, invalid_hash]), expected_results);
    sui::test_utils::destroy(lc);
    scenario.end();
}
