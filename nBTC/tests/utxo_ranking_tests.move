#[test_only]
module nbtc::utxo_ranking_tests;

use nbtc::nbtc_utxo::{new_utxo, utxo_ranking};
use std::unit_test::assert_eq;

const ACTIVE_KEY: vector<u8> = x"0014e8340a12dd2c95e5fedc8b088a81dcac42c106fb";
const INACTIVE_KEY_1: vector<u8> = x"00149b622481f0407714dd3ef4850a02ffbdc19dfa96";
macro fun MOCK_DWALLET_ID(): ID {
    object::id_from_address(@0x01)
}
// Multiple UTXOs with exact match vs fewer UTXOs with change
#[test]
fun exact_match_wins_over_change() {
    let active = ACTIVE_KEY;
    let withdraw = 100_000_000;

    let utxos1 = vector[
        new_utxo(
            x"a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1",
            0,
            35_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2",
            1,
            30_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3",
            0,
            20_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4",
            2,
            15_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
    ];
    let score1 = utxo_ranking(&utxos1, withdraw, &active);

    let utxos2 = vector[
        new_utxo(
            x"e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5",
            0,
            110_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6",
            1,
            80_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7",
            0,
            50_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
    ];
    let score2 = utxo_ranking(&utxos2, withdraw, &active);

    assert_eq!(score1 > score2, true);
}

// 0.6 + 0.4 BTC (inactive keys) vs 1.1 BTC (active key)
#[test]
fun inactive_keys_with_exact_match_rank_above() {
    let active = ACTIVE_KEY;
    let inactive1 = INACTIVE_KEY_1;
    let withdraw = 100_000_000;

    let utxos1 = vector[
        new_utxo(
            x"b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8",
            0,
            60_000_000,
            inactive1,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9",
            1,
            40_000_000,
            inactive1,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1dad1",
            2,
            30_000_000,
            inactive1,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2ebe2",
            0,
            20_000_000,
            inactive1,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3fcf3",
            1,
            10_000_000,
            inactive1,
            MOCK_DWALLET_ID!(),
        ),
    ];
    let score1 = utxo_ranking(&utxos1, withdraw, &active);

    let utxos2 = vector[
        new_utxo(
            x"a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0",
            0,
            110_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1",
            2,
            90_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2",
            1,
            70_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3",
            0,
            50_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
    ];
    let score2 = utxo_ranking(&utxos2, withdraw, &active);

    assert_eq!(score1 > score2, true);
}

// 1.1 BTC (with change) vs 5×0.2 BTC (exact match)
#[test]
fun minimize_inputs_priority() {
    let active = ACTIVE_KEY;
    let withdraw = 100_000_000;

    let utxos1 = vector[
        new_utxo(
            x"1111111111111111111111111111111111111111111111111111111111111111",
            0,
            110_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
    ];
    let score1 = utxo_ranking(&utxos1, withdraw, &active);

    let utxos2 = vector[
        new_utxo(
            x"2222222222222222222222222222222222222222222222222222222222222222",
            0,
            20_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"3333333333333333333333333333333333333333333333333333333333333333",
            1,
            20_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"4444444444444444444444444444444444444444444444444444444444444444",
            0,
            20_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"5555555555555555555555555555555555555555555555555555555555555555",
            2,
            20_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
        new_utxo(
            x"6666666666666666666666666666666666666666666666666666666666666666",
            1,
            20_000_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
    ];
    let score2 = utxo_ranking(&utxos2, withdraw, &active);

    assert_eq!(score2 > score1, true);
}

// Dust change vs clean change
#[test]
fun dust_penalized() {
    let active = ACTIVE_KEY;
    let withdraw = 100_000_000;

    let utxos_dust = vector[
        new_utxo(
            x"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            0,
            100_008_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
    ];
    let score_dust = utxo_ranking(&utxos_dust, withdraw, &active);

    let utxos_clean = vector[
        new_utxo(
            x"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            0,
            100_050_000,
            active,
            MOCK_DWALLET_ID!(),
        ),
    ];
    let score_clean = utxo_ranking(&utxos_clean, withdraw, &active);

    assert_eq!(score_clean > score_dust, true);
}
