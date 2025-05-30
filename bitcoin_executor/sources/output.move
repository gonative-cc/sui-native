module bitcoin_executor::output;
use bitcoin_executor::utils::vector_slice;


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
