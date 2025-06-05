// SPDX-License-Identifier: MPL-2.0

module bitcoin_executor::utxo;

use bitcoin_executor::output::Output;
use bitcoin_executor::input::Input;

use bitcoin_executor::utils::{vector_slice, u32_to_le_bytes, LEtoNumber};

const OP_0: u8 = 0x00;
const OP_DATA_20: u8 = 0x14;

/// We represent UTXOs as a map of {key: OutPoint, value: Data}
/// OutPoint is a name used to identify UTXO in bitcoind
/// OutPoint is a UTXO ID
public struct OutPoint has copy, drop, store {
    tx_id: vector<u8>,
    vout: u32,
    vout_bytes: vector<u8>,
}

/// Data is a UTXO value
public struct Data has copy, drop, store {
    height: u64, // The height of the block containing the UTXO.
    is_coinbase: bool, // Whether the UTXO is from a coinbase transaction or not.
    output: Output,
}

public fun new_outpoint(tx_id: vector<u8>, vout: u32): OutPoint {
    OutPoint { tx_id, vout, vout_bytes: u32_to_le_bytes(vout) }
}

public fun from_input(input: &Input): OutPoint {
    OutPoint {
        tx_id: input.tx_id(),
        vout: LEtoNumber(input.vout()) as u32,
        vout_bytes: input.vout()
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
    output: Output
): (OutPoint, Data) {
    (new_outpoint(tx_id, vout), new_data(height, is_coinbase, output))
}

public fun tx_id(outpoint: &OutPoint): vector<u8> { outpoint.tx_id }

public fun vout(outpoint: &OutPoint): u32 { outpoint.vout }

public fun vout_bytes(outpoint: &OutPoint): vector<u8> { outpoint.vout_bytes }

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
