module nbtc::config;

/// Config for NBTC
public struct Config has key, store {
    id: UID,
    // Bitcoin light client
    light_client_id: ID,
    mint_fee: u64,
    fallback_addr: address,
}

public fun new(
    light_client_id: ID,
    fallback_addr: address,
    mint_fee: u64,
    ctx: &mut TxContext,
): Config {
    Config {
        id: object::new(ctx),
        light_client_id,
        mint_fee,
        fallback_addr,
    }
}

public fun light_client_id(config: &Config): ID {
    config.light_client_id
}

public fun mint_fee(config: &Config): u64 {
    config.mint_fee
}

public fun fallback_addr(config: &Config): address {
    config.fallback_addr
}

public fun set_mint_fee(config: &mut Config, fee: u64) {
    config.mint_fee = fee
}
