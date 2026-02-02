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

// Common test constants - as public macros
public macro fun NBTC_TAPROOT_SCRIPT(): vector<u8> {
    x"51200f0c8db753acbd17343a39c2f3f4e35e4be6da749f9e35137ab220e7b238a667"
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

// Mock signature used across signature-related tests
public macro fun MOCK_SIGNATURE(): vector<u8> {
    x"b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae"
}

// Secondary transaction hash for multi-input tests
public macro fun TX_HASH_2(): vector<u8> {
    x"02ce677fd511851bb6cdacebed863d12dfd231d810e8e9fcba6e791001adf3a6"
}

public macro fun TEST_SIGN_ID_1(): ID {
    object::id_from_address(@0x2)
}

public macro fun TEST_SIGN_ID_2(): ID {
    object::id_from_address(@0x3)
}

// Simple UTXO identifiers for tests
public macro fun UTXO_HASH_1(): vector<u8> {
    x"01"
}

public macro fun UTXO_HASH_2(): vector<u8> {
    x"02"
}

public macro fun UTXO_HASH_3(): vector<u8> {
    x"03"
}

public macro fun UTXO_HASH_4(): vector<u8> {
    x"04"
}

// Alternative script for different treasury address
public macro fun ALTERNATIVE_NBTC_SCRIPT(): vector<u8> {
    x"76a914509a651dd392e1bc125323f629b67d65cca3d4ff88ac"
}
