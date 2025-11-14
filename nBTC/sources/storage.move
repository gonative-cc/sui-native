module nbtc::storage;

use ika_dwallet_2pc_mpc::coordinator_inner::DWalletCap;
use sui::table::{Self, Table};

public struct DWalletMetadata has store {
    // TODO: change to taproot once Ika will support it
    public_key: vector<u8>, // ecdsa public key
    lockscript: vector<u8>, // lock script for this dwallet
    script_type: u8, // script type, not sure we need this
    active: bool, // active flag
    total_deposit: u64, // total deposit balance
    // map address to amount they deposit/mint
    // only record when wallet is inactive
    inactive_balances: Table<address, u64>,
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
        inactive_balances: table::new(ctx),
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

public fun inactive_balances(dmeta: &DWalletMetadata, addr: address): u64 {
    if (dmeta.inactive_balances.contains(addr)) {
        dmeta.inactive_balances[addr]
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
    if (dwallet_metadata_mut.inactive_balances.contains(user)) {
        let user_balance = &mut dwallet_metadata_mut.inactive_balances[user];
        *user_balance = *user_balance + amount;
    } else {
        dwallet_metadata_mut.inactive_balances.add(user, amount);
    };
    dwallet_metadata_mut.total_deposit = dwallet_metadata_mut.total_deposit + amount;
}

public(package) fun remove_inactive_balance(
    store: &mut Storage,
    dwallet_id: ID,
    user: address,
): u64 {
    let dwallet_metadata_mut = &mut store.dwallet_metadatas[dwallet_id];
    let user_balance = &mut dwallet_metadata_mut.inactive_balances[user];
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

public(package) fun add_metadata(store: &mut Storage, dwallet_id: ID, dmeta: DWalletMetadata) {
    store.dwallet_metadatas.add(dwallet_id, dmeta);
}

public(package) fun add_dwallet_cap(store: &mut Storage, dwallet_id: ID, dwallet_cap: DWalletCap) {
    store.dwallet_caps.add(dwallet_id, dwallet_cap);
}

public(package) fun increase_total_deposit(store: &mut Storage, dwallet_id: ID, amount: u64) {
    let dwallet_metadata_mut = &mut store.dwallet_metadatas[dwallet_id];
    let total_deposit = &mut dwallet_metadata_mut.total_deposit;
    *total_deposit = *total_deposit + amount;
}

public(package) fun remove(store: &mut Storage, dwallet_id: ID) {
    let DWalletMetadata {
        inactive_balances,
        total_deposit: _,
        script_type: _,
        active: _,
        lockscript: _,
        public_key: _,
    } = store.dwallet_metadatas.remove(dwallet_id);
    inactive_balances.drop();
}
// // return wallet id have lock script
// public(package) fun lookup_spend_key(store: &Storage, lockscript: vector<u8>): ID {
//
// }
