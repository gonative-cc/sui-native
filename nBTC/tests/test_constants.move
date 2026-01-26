#[test_only]
module nbtc::test_constants;

// Mock dwallet ID used across tests
public macro fun MOCK_DWALLET_ID(): ID {
    object::id_from_address(@0x01)
}

// Second mock dwallet ID for tests
public macro fun MOCK_DWALLET_ID_2(): ID {
    object::id_from_address(@0x02)
}

// Fallback address for receiving nBTC if OP_RETURN data is invalid or missing
public macro fun FALLBACK_ADDR(): address {
    @0xB0B
}

// Common test constants - as public macros
public macro fun NBTC_SCRIPT_PUBKEY(): vector<u8> {
    x"76a914509a651dd392e1bc125323f629b67d65cca3d4bb88ac"
}

public macro fun ADMIN(): address {
    @0xad
}

public macro fun TX_HASH(): vector<u8> {
    x"06ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6"
}

public macro fun REDEEM_FEE(): u64 {
    150
}

public macro fun RECEIVER_SCRIPT(): vector<u8> {
    x"00140000000000000000000000000000000000000002"
}
