module nbtc::config;

/// Metadata for nBTC hold the information about btc light client object, fee
/// and default fallback address
public struct Config has key, store {
    id: UID,
    // Bitcoin light client
    light_client_id: ID,
    // nBTC mint fee on sui
    mint_fee: u64,
    // fallback address, we mint nbtc to this address
    // when user don't set OP_RETURN script
    fallback_addr: address,
    // dwallet coordinator object id
    dwallet_coordinator: ID,
}

public fun new(
    light_client_id: ID,
    fallback_addr: address,
    mint_fee: u64,
    dwallet_coordinator: ID,
    ctx: &mut TxContext,
): Config {
    Config {
        id: object::new(ctx),
        light_client_id,
        mint_fee,
        fallback_addr,
        dwallet_coordinator,
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

public fun dwallet_coordinator(config: &Config): ID {
    config.dwallet_coordinator
}

public(package) fun set_mint_fee(config: &mut Config, fee: u64) {
    config.mint_fee = fee
}
