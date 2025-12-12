#[test_only]
module nbtc::utxo_ranking_tests;

use nbtc::nbtc_utxo::{new_utxo, utxo_ranking, new_utxo_store};
use nbtc::test_constants::{MOCK_DWALLET_ID, MOCK_DWALLET_ID_2};
use std::unit_test::{assert_eq, destroy};
use sui::test_scenario;

const INACTIVE_KEY_1: vector<u8> = x"00149b622481f0407714dd3ef4850a02ffbdc19dfa96";

// Multiple UTXOs with exact match vs fewer UTXOs with change
#[test]
fun exact_match_wins_over_change() {
    let mut scenario = test_scenario::begin(@0x1);
    let ctx = scenario.ctx();

    let mut utxo_map = new_utxo_store(ctx);
    let active_dwallet_id = MOCK_DWALLET_ID!();
    let inactive_dwallet_id = MOCK_DWALLET_ID_2!();

    // Add UTXOs to the map
    let utxo1 = new_utxo(
        x"a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1",
        0,
        35_000_000,
    );
    utxo_map.add(active_dwallet_id, utxo1);

    let utxo2 = new_utxo(
        x"b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2",
        1,
        30_000_000,
    );
    utxo_map.add(active_dwallet_id, utxo2);

    let utxo3 = new_utxo(
        x"c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3",
        0,
        20_000_000,
    );
    utxo_map.add(active_dwallet_id, utxo3);

    let utxo4 = new_utxo(
        x"d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4",
        2,
        15_000_000,
    );
    utxo_map.add(active_dwallet_id, utxo4);

    let utxo_ids1 = vector[0, 1, 2, 3];
    let dwallet_ids1 = vector[
        active_dwallet_id,
        active_dwallet_id,
        active_dwallet_id,
        active_dwallet_id,
    ];
    let withdraw = 100_000_000;

    let score1 = utxo_ranking(&utxo_map, utxo_ids1, dwallet_ids1, withdraw, active_dwallet_id);

    // Create second set of UTXOs
    let mut utxo_map2 = new_utxo_store(ctx);

    let utxo5 = new_utxo(
        x"e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5",
        0,
        110_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo5);

    let utxo6 = new_utxo(
        x"f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6",
        1,
        80_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo6);

    let utxo7 = new_utxo(
        x"a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7",
        0,
        50_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo7);

    let utxo_ids2 = vector[0, 1, 2];
    let dwallet_ids2 = vector[active_dwallet_id, active_dwallet_id, active_dwallet_id];

    let score2 = utxo_ranking(&utxo_map2, utxo_ids2, dwallet_ids2, withdraw, active_dwallet_id);

    assert_eq!(score1 > score2, true);

    destroy(utxo_map);
    destroy(utxo_map2);
    test_scenario::end(scenario);
}

// 0.6 + 0.4 BTC (inactive keys) vs 1.1 BTC (active key)
#[test]
fun inactive_keys_with_exact_match_rank_above() {
    let mut scenario = test_scenario::begin(@0x1);
    let ctx = scenario.ctx();

    let mut utxo_map = new_utxo_store(ctx);
    let active_dwallet_id = MOCK_DWALLET_ID!();
    let inactive_dwallet_id = MOCK_DWALLET_ID_2!();

    // Add UTXOs to the map
    let utxo1 = new_utxo(
        x"b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8",
        0,
        60_000_000,
    );
    utxo_map.add(inactive_dwallet_id, utxo1);

    let utxo2 = new_utxo(
        x"c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9",
        1,
        40_000_000,
    );
    utxo_map.add(inactive_dwallet_id, utxo2);

    let utxo3 = new_utxo(
        x"dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1",
        2,
        30_000_000,
    );
    utxo_map.add(inactive_dwallet_id, utxo3);

    let utxo4 = new_utxo(
        x"ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2",
        0,
        20_000_000,
    );
    utxo_map.add(inactive_dwallet_id, utxo4);

    let utxo5 = new_utxo(
        x"fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3",
        1,
        10_000_000,
    );
    utxo_map.add(inactive_dwallet_id, utxo5);

    let utxo_ids1 = vector[0, 1, 2, 3, 4];
    let dwallet_ids1 = vector[
        inactive_dwallet_id,
        inactive_dwallet_id,
        inactive_dwallet_id,
        inactive_dwallet_id,
        inactive_dwallet_id,
    ];
    let withdraw = 100_000_000;

    let score1 = utxo_ranking(&utxo_map, utxo_ids1, dwallet_ids1, withdraw, active_dwallet_id);

    // Create second set of UTXOs
    let mut utxo_map2 = new_utxo_store(ctx);

    let utxo6 = new_utxo(
        x"a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0",
        0,
        110_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo6);

    let utxo7 = new_utxo(
        x"b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1",
        2,
        90_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo7);

    let utxo8 = new_utxo(
        x"c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2",
        1,
        70_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo8);

    let utxo9 = new_utxo(
        x"d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3",
        0,
        50_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo9);

    let utxo_ids2 = vector[0, 1, 2, 3];
    let dwallet_ids2 = vector[
        active_dwallet_id,
        active_dwallet_id,
        active_dwallet_id,
        active_dwallet_id,
    ];

    let score2 = utxo_ranking(&utxo_map2, utxo_ids2, dwallet_ids2, withdraw, active_dwallet_id);

    assert_eq!(score1 > score2, true);

    destroy(utxo_map);
    destroy(utxo_map2);
    test_scenario::end(scenario);
}

// 1.1 BTC (with change) vs 5×0.2 BTC (exact match)
#[test]
fun minimize_inputs_priority() {
    let mut scenario = test_scenario::begin(@0x1);
    let ctx = scenario.ctx();

    let mut utxo_map = new_utxo_store(ctx);
    let active_dwallet_id = MOCK_DWALLET_ID!();

    // Add UTXOs to the map
    let utxo1 = new_utxo(
        x"1111111111111111111111111111111111111111111111111111111111111111",
        0,
        110_000_000,
    );
    utxo_map.add(active_dwallet_id, utxo1);

    let utxo_ids1 = vector[0];
    let dwallet_ids1 = vector[active_dwallet_id];
    let withdraw = 100_000_000;

    let score1 = utxo_ranking(&utxo_map, utxo_ids1, dwallet_ids1, withdraw, active_dwallet_id);

    // Create second set of UTXOs
    let mut utxo_map2 = new_utxo_store(ctx);

    let utxo2 = new_utxo(
        x"2222222222222222222222222222222222222222222222222222222222222222",
        0,
        20_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo2);

    let utxo3 = new_utxo(
        x"3333333333333333333333333333333333333333333333333333333333333333",
        1,
        20_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo3);

    let utxo4 = new_utxo(
        x"4444444444444444444444444444444444444444444444444444444444444444",
        2,
        20_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo4);

    let utxo5 = new_utxo(
        x"5555555555555555555555555555555555555555555555555555555555555555",
        3,
        20_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo5);

    let utxo6 = new_utxo(
        x"6666666666666666666666666666666666666666666666666666666666666666",
        4,
        20_000_000,
    );
    utxo_map2.add(active_dwallet_id, utxo6);

    let utxo_ids2 = vector[0, 1, 2, 3, 4];
    let dwallet_ids2 = vector[
        active_dwallet_id,
        active_dwallet_id,
        active_dwallet_id,
        active_dwallet_id,
        active_dwallet_id,
    ];

    let score2 = utxo_ranking(&utxo_map2, utxo_ids2, dwallet_ids2, withdraw, active_dwallet_id);

    assert_eq!(score2 > score1, true);

    destroy(utxo_map);
    destroy(utxo_map2);
    test_scenario::end(scenario);
}

// Dust change vs clean change
#[test]
fun dust_penalized() {
    let mut scenario = test_scenario::begin(@0x1);
    let ctx = scenario.ctx();

    let mut utxo_map = new_utxo_store(ctx);
    let active_dwallet_id = MOCK_DWALLET_ID!();

    // Add dust UTXO
    let utxo1 = new_utxo(
        x"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        0,
        100_008_000,
    );
    utxo_map.add(active_dwallet_id, utxo1);

    let utxo_ids1 = vector[0];
    let dwallet_ids1 = vector[active_dwallet_id];
    let withdraw = 100_000_000;

    let score_dust = utxo_ranking(&utxo_map, utxo_ids1, dwallet_ids1, withdraw, active_dwallet_id);

    // Create clean UTXO
    let mut utxo_map2 = new_utxo_store(ctx);

    let utxo2 = new_utxo(
        x"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        0,
        100_050_000,
    );
    utxo_map2.add(active_dwallet_id, utxo2);

    let utxo_ids2 = vector[0];
    let dwallet_ids2 = vector[active_dwallet_id];

    let score_clean = utxo_ranking(
        &utxo_map2,
        utxo_ids2,
        dwallet_ids2,
        withdraw,
        active_dwallet_id,
    );

    assert_eq!(score_clean > score_dust, true);

    destroy(utxo_map);
    destroy(utxo_map2);
    test_scenario::end(scenario);
}
