module nbtc::storage;

use ika_dwallet_2pc_mpc::coordinator_inner::DWalletCap;
use sui::table::{Self, Table};

public struct DWalletMetadata has store {
    public_key: vector<u8>, // ecdsa public key
    lockscript: vector<u8>, // lock script for this dwallet
    script_type: u8, // script type, not sure we need this
    active: bool, // active flag
    total_deposit: u64, // totanle deposit balance
    // map address to amount they deposit/mint
    // only record when active invalid
    record_balance: Table<address, u64>,
}

public struct Storage has key, store {
    id: UID,
    active_dwallet_id: ID, // id of active dwallet
    // map dwallet id to Dwallet Metadata
    dwallet_metadatas: Table<ID, DWalletMetadata>,
    dwallet_caps: Table<ID, DWalletCap>,
}

public fun create_dwallet_metadata(
    script_type: u8,
    lockscript: vector<u8>,
    public_key: vector<u8>,
    ctx: &mut TxContext,
): DWalletMetadata {
    DWalletMetadata {
        public_key,
        lockscript,
        script_type,
        active: false,
        total_deposit: 0,
        record_balance: table::new(ctx),
    }
}

public fun public_key(dmeta: &DWalletMetadata): vector<u8> {
    dmeta.public_key
}

public fun lockscript(dmeta: &DWalletMetadata): vector<u8> {
    dmeta.lockscript
}

public fun script_type(dmeta: &DWalletMetadata): u8 {
    dmeta.script_type
}

public fun active(dmeta: &DWalletMetadata): bool {
    dmeta.active
}

public fun total_deposit(dmeta: &DWalletMetadata): u64 {
    dmeta.total_deposit
}

public fun record_balance_of(dmeta: &DWalletMetadata, addr: address): u64 {
    if (dmeta.record_balance.contains(addr)) {
        dmeta.record_balance[addr]
    } else {
        // they don't use this wallet
        0
    }
}

public fun dwallet_metadata(store: &Storage, dwallet_id: ID): &DWalletMetadata {
    &store.store.dwallet_metadatas[dwallet_id]
}

// NOTE: This function never export to public
public(package) fun dwallet_cap(store: &Storage, dwallet_id: ID): &DWalletCap {
    &store.dwallet_caps[dwallet_id]
}
