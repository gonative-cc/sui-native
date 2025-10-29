// TODO: Refactor to bitcoinlib
module nbtc::nbtc_utxo;

// TODO: we need to store them by owner (the nBTC key)?
public struct Utxo has copy, drop, store {
    tx_id: vector<u8>, // TODO: this is 32-byte hash. we can also use vector<u8>
    vout: u32,
    value: u64,
}

public fun new_utxo(tx_id: vector<u8>, vout: u32, value: u64): Utxo {
    Utxo {
        tx_id,
        vout,
        value,
    }
}

public fun tx_id(utxo: &Utxo): vector<u8> {
    utxo.tx_id
}

public fun vout(utxo: &Utxo): u32 {
    utxo.vout
}

public fun value(utxo: &Utxo): u64 {
    utxo.value
}
