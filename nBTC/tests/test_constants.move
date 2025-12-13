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
