module btc_parser::output;

use btc_parser::utils::u64_to_le_bytes;

/// Output in btc transaction
public struct Output has copy, drop, store {
    amount: u64,
    amount_bytes: vector<u8>,
    script_pubkey: vector<u8>,
}

public fun new(amount: u64, script_pubkey: vector<u8>): Output {
    Output {
        amount,
        amount_bytes: u64_to_le_bytes(amount),
        script_pubkey,
    }
}

public fun amount_bytes(output: &Output): vector<u8> {
    output.amount_bytes
}
public fun amount(output: &Output): u64 {
    output.amount
}

public fun script_pubkey(output: &Output): vector<u8> {
    output.script_pubkey
}
