// SPDX-License-Identifier: MPL-2.0

#[test_only]
module bitcoin_executor::interpreter_tests;

use bitcoin_executor::interpreter::{create_p2wpkh_scriptcode, run};
use bitcoin_executor::stack::new_with_data;
use btc_parser::reader;
use btc_parser::tx::deserialize;
use std::unit_test::assert_eq;

#[test]
fun run_segwit_script() {
    let data =
        x"020000000001019dafd815a150414d02047a22ab806dbd2f43d0e1ea5922dadd5396f6d67769202900000000ffffffff01e91801000000000016001464f9139a4a853b3d5ad1315ceb707386ed343c2c02473044022063db5a24fec209152863fb251cc349a7030220bf4ca6e6296002d46d4c3651a502205a0b4b5a520fc42b91b8a888351c1c42bd2864aba2c398007405e957dea77bb101210329cdb63380e0a7109773703534659df6be41c48b4e80e5da77eb384ff7d41be200000000";
    let mut r = reader::new(data);
    let tx = deserialize(&mut r);
    let amount = 72569;
    let index = 0;
    let stack = new_with_data(tx.witness()[0].items());
    let pk = x"5c2dc82f606be66506b7403f9b304f5e0908b652";
    let script = create_p2wpkh_scriptcode(pk);
    let ans = run(tx, stack, script, index, amount);
    assert_eq!(ans, true)
}
