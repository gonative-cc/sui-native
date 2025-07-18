// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::utxo;

use btc_parser::input::Input;
use btc_parser::output::Output;
use btc_parser::utils::{vector_slice, le_bytes_to_u64};

const OP_0: u8 = 0x00;
const OP_DATA_20: u8 = 0x14;

/// We represent UTXOs as a map of {key: OutPoint, value: Data}
/// OutPoint is a name used to identify UTXO in bitcoind
/// OutPoint is a UTXO ID
public struct OutPoint has copy, drop, store {
    tx_id: vector<u8>,
    vout: u32,
}

/// Data is a UTXO value
public struct Data has copy, drop, store {
    height: u64, // The height of the block containing the UTXO.
    is_coinbase: bool, // Whether the UTXO is from a coinbase transaction or not.
    output: Output,
}

public fun new_outpoint(tx_id: vector<u8>, vout: u32): OutPoint {
    OutPoint { tx_id, vout }
}

public fun from_input(input: &Input): OutPoint {
    OutPoint {
        tx_id: input.tx_id(),
        vout: le_bytes_to_u64(input.vout()) as u32,
    }
}

public fun new_data(height: u64, is_coinbase: bool, output: Output): Data {
    Data { height, is_coinbase, output }
}

public fun new(
    tx_id: vector<u8>,
    vout: u32,
    height: u64,
    is_coinbase: bool,
    output: Output,
): (OutPoint, Data) {
    (new_outpoint(tx_id, vout), new_data(height, is_coinbase, output))
}

public fun tx_id(outpoint: &OutPoint): vector<u8> { outpoint.tx_id }

public fun vout(outpoint: &OutPoint): u32 { outpoint.vout }

public fun output(data: &Data): &Output {
    &data.output
}

public fun height(data: &Data): u64 { data.height }

public fun is_coinbase(data: &Data): bool { data.is_coinbase }

/// Extract pkh from witness program.
public fun pkh(data: &Data): vector<u8> {
    // TODO: we should refactor data to Output friendly format.
    let script = data.output().script_pubkey();
    let is_wphk =
        script.length() == 22 &&
        script[0] == OP_0 &&
        script[1] == OP_DATA_20;

    if (is_wphk) {
        vector_slice(&script, 2, 22)
    } else {
        vector[]
    }
}
