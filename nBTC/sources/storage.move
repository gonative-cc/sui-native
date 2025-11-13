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
    // map dwallet id to Dwallet Metadata
    dwallet_metadatas: Table<ID, DWalletMetadata>,
    // lockscript: Table<vector<u8>, ID>,
    dwallet_caps: Table<ID, DWalletCap>,
}

// TODO: OTW for create_dwallet_metadata
public(package) fun create_dwallet_metadata(
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

public(package) fun increase_record_balance(
    store: &mut Storage,
    dwallet_id: ID,
    user: address,
    amount: u64,
) {
    let dwallet_metadata_mut = &mut store.dwallet_metadatas[dwallet_id];
    if (dwallet_metadata_mut.record_balance.contains(user)) {
        let user_balance = &mut dwallet_metadata_mut.record_balance[user];
        *user_balance = *user_balance + amount;
    } else {
        dwallet_metadata_mut.record_balance.add(user, amount);
    };
    dwallet_metadata_mut.total_deposit = dwallet_metadata_mut.total_deposit + amount;
}

public(package) fun remove_record_balance(store: &mut Storage, dwallet_id: ID, user: address): u64 {
    let dwallet_metadata_mut = &mut store.dwallet_metadatas[dwallet_id];
    let user_balance = &mut dwallet_metadata_mut.record_balance[user];
    let amount = *user_balance;
    *user_balance = 0;
    dwallet_metadata_mut.total_deposit = dwallet_metadata_mut.total_deposit - amount;
    amount
}

public fun dwallet_metadata(store: &Storage, dwallet_id: ID): &DWalletMetadata {
    &store.dwallet_metadatas[dwallet_id]
}

// NOTE: This function never export to public
public(package) fun dwallet_cap(store: &Storage, dwallet_id: ID): &DWalletCap {
    &store.dwallet_caps[dwallet_id]
}

// TODO: OTW for create_storage
public fun create_storage(ctx: &mut TxContext): Storage {
    Storage {
        id: object::new(ctx),
        dwallet_caps: table::new(ctx),
        dwallet_metadatas: table::new(ctx),
    }
}

public fun exist(store: &Storage, dwallet_id: ID): bool {
    store.dwallet_metadatas.contains(dwallet_id)
}

public fun add_metadata(store: &mut Storage, dwallet_id: ID, dmeta: DWalletMetadata) {
    store.dwallet_metadatas.add(dwallet_id, dmeta);
}

public fun add_dwallet_cap(store: &mut Storage, dwallet_id: ID, dwallet_cap: DWalletCap) {
    store.dwallet_caps.add(dwallet_id, dwallet_cap);
}
// // return wallet id have lock script
// public(package) fun lookup_spend_key(store: &Storage, lockscript: vector<u8>): ID {
//
// }
