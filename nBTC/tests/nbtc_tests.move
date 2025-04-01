#[test_only]
module nbtc::nbtc_tests;

use nbtc::nbtc::{Self, WrappedTreasuryCap, NBTC};
use bitcoin_spv::light_client::{new_light_client_with_params_without_share, LightClient};
use bitcoin_spv::params;

#[test_only]
fun new_lc_for_test(ctx: &mut TxContext) : LightClient {
    let start_block = 858806;
    let headers = vector[
        x"00000020a97594d6b5b9369535da225d464bde7e0ae3794e9b270a010000000000000000879574acf5757cd2af60949ff20faddd581aaebc6d2327646cb84f0d11fc1cc2bb27e8585a330218b119eaee"
    ];
    let lc = new_light_client_with_params_without_share(params::mainnet(), start_block, headers, 0, 8, ctx);
    return lc
}

#[test_only]
fun init_nbtc(ctx: &mut TxContext): (LightClient, WrappedTreasuryCap) {
    let lc = new_lc_for_test(ctx);
    let lc_id = lc.client_id().uid_to_inner();
    let cap = nbtc::init_for_testing(lc_id, ctx);
    (lc, cap)
}

#[test]
fun test_nbtc_mint() {
    let (lc, cap) = init_nbtc();
}

// #[test, expected_failure(abort_code = ::nbtc::nbtc_tests::ENotImplemented)]
// fun test_nbtc_fail() {
//     abort ENotImplemented
// }
