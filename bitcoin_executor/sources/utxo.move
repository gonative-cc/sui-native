module bitcoin_executor::utxo;

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

public fun new_data(height: u64, is_coinbase: bool, value: u64, script_pub_key: vector<u8>): Info {
    Info { height, is_coinbase, value, script_pub_key }
}

public fun new(
    tx_id: vector<u8>,
    vout: u32,
    height: u64,
    is_coinbase: bool,
    value: u64,
    script_pub_key: vector<u8>,
): (OutPoint, Info) {
    (OutPoint { tx_id, vout }, Info { height, is_coinbase, value, script_pub_key })
}

public fun tx_id(outpoint: &OutPoint): vector<u8> { outpoint.tx_id }

public fun vout(outpoint: &OutPoint): u32 { outpoint.vout }

public fun value(info: &Info): u64 { info.value }

public fun script_pub_key(info: &Info): &vector<u8> { &info.script_pub_key }

public fun height(info: &Info): u64 { info.height }

public fun is_coinbase(info: &Info): bool { info.is_coinbase }
