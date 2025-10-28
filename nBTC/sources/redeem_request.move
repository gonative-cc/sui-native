module nbtc::redeem_request;

use nbtc::utxo::Utxo;

public enum RedeemStatus has copy, drop, store {
    Resolving, // finding the best UTXOs
    Signing,
    Signed,
    Confirmed,
}

public struct RedeemRequest has store {
    // TODO: maybe we don't need the ID?
    redeemer: address, // TODO: maybe it's not needed
    /// Bitcoin spent key (address)
    recipient: vector<u8>,
    status: RedeemStatus,
    amount: u64,
    inputs: vector<Utxo>,
    remainder_output: Utxo,
}

public fun is_signing(status: &RedeemStatus): bool {
    match (status) {
        RedeemStatus::Signing => true,
        _ => false,
    }
}

public fun status(r: &RedeemRequest): &RedeemStatus {
    &r.status
}
