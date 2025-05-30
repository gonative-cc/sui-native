module bitcoin_executor::utxo;

use bitcoin_executor::utils::vector_slice;

const OP_0: u8 = 0x00;
const OP_DATA_20: u8 = 0x14;


public struct OutPoint has copy, drop, store {
    tx_id: vector<u8>,
    vout: u32,
}

public struct Data has copy, drop, store {
    height: u64, // The height of the block containing the UTXO.
    is_coinbase: bool, // Whether the UTXO is from a coinbase transaction or not.
    value: u64, // Amount in satoshis
    script_pub_key: vector<u8>, // The locking script
}

public fun new_outpoint(tx_id: vector<u8>, vout: u32): OutPoint {
    OutPoint { tx_id, vout }
}

public fun new_data(height: u64, is_coinbase: bool, value: u64, script_pub_key: vector<u8>): Data {
    Data { height, is_coinbase, value, script_pub_key }
}

public fun new(
    tx_id: vector<u8>,
    vout: u32,
    height: u64,
    is_coinbase: bool,
    value: u64,
    script_pub_key: vector<u8>,
): (OutPoint, Data) {
    (OutPoint { tx_id, vout }, Data { height, is_coinbase, value, script_pub_key })
}

public fun tx_id(outpoint: &OutPoint): vector<u8> { outpoint.tx_id }

public fun vout(outpoint: &OutPoint): u32 { outpoint.vout }

public fun value(data: &Data): u64 { data.value }

public fun script_pub_key(data: &Data): &vector<u8> { &data.script_pub_key }

public fun height(data: &Data): u64 { data.height }

public fun is_coinbase(data: &Data): bool { data.is_coinbase }


public fun pkh(data: &Data): vector<u8> {
    let script = data.script_pub_key;
    let is_wphk = script.length() == 22 &&
        script[0] == OP_0 &&
        script[1] == OP_DATA_20;

    if (is_wphk) {
        vector_slice(&script, 2, 22)
    } else {
        vector[]
    }
}
