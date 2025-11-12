module nbtc::storage;

public struct DWalletMetadata has copy, drop, store {
    public_key: vector<u8>, // ecdsa public key
    lockscript: vector<u8>, // lock script for this dwallet
    script_type: u8, // script type, not sure we need this
    active: bool, // active flag
    total_deposit: u64, // totanle deposit balance
    dwallet_cap: DWalletCap,
    record_balance: Table<address, u64>,
}

public struct Storage has key, store {
    id: UID,
    active_dwallet_id: ID, // id of active dwallet
    dwallet_maps: Table<ID, DwalletMetadata>,
}

public fun create_dwallet_metadata(
    dwallet_cap: DWalletCap,
    script_type: u8,
    lockscript: vector<u8>,
    public_key: vector<u8>,
    ctx: &mut TxContext,
): DWalletMetadata {
    DwalletMetadata {
        dwallet_cap,
        public_key,
        lockscript,
        script_type,
        active: false,
        total_deposit: 0,
        record_balance: table::new(ctx),
    }
}
