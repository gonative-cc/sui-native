module bitcoin_executor::output;
use bitcoin_executor::utils::vector_slice;

const OP_0: u8 = 0x00;
const OP_DATA_20: u8 = 0x14;

/// Output in btc transaction
public struct Output has copy, drop {
    script_pubkey: vector<u8>,
    amount: vector<u8>,
}

public fun new(amount: vector<u8>, script_pubkey: vector<u8>): Output {
    Output {
        amount,
        script_pubkey,
    }
}

public fun amount(output: &Output): vector<u8> {
    output.amount
}

public fun script_pubkey(output: &Output) : vector<u8> {
    output.script_pubkey
}

public fun pkh(output: &Output): vector<u8> {
    let script = output.script_pubkey;
    let is_wphk = script.length() == 22 &&
        script[0] == OP_0 &&
        script[1] == OP_DATA_20;

    if (is_wphk) {
        vector_slice(&script, 2, 22)
    } else {
        vector[]
    }
}
