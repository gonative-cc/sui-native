module nbtc::storage;

use ika_dwallet_2pc_mpc::coordinator_inner::DWalletCap;
use sui::table::{Self, Table};

public struct DWalletMetadata has store {
    // TODO: change to taproot once Ika will support it
    // we don't derive lockscript to public key
    // the reason is this require ripend160 hash function
    // and we don't have efficiency implementation in sui for this hash function
    public_key: vector<u8>, // public key
    public_key_type: u8, // type of public key of dwallet
    lockscript: vector<u8>, // lock script for this dwallet
    script_type: u8, // script type, not sure we need this
    total_deposit: u64, // total deposit balance
    user_share: vector<u8>, // public user_share for this nbtc dwallet endpoint
    // map address to amount they deposit/mint
    // only record when wallet is inactive
    inactive_balances: Table<address, u64>,
}

public struct Storage has key, store {
    id: UID,
    // map dwallet id to Dwallet Metadata
    // TODO: consider vector or Table for store metadata
    dwallet_metadatas: Table<ID, DWalletMetadata>,
    dwallet_caps: Table<ID, DWalletCap>,
}

public(package) fun create_dwallet_metadata(
    script_type: u8,
    lockscript: vector<u8>,
    public_key: vector<u8>,
    user_share: vector<u8>,
    ctx: &mut TxContext,
): DWalletMetadata {
    DWalletMetadata {
        public_key,
        lockscript,
        script_type,
        public_key_type: 0,
        total_deposit: 0,
        user_share,
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

public fun total_deposit(dmeta: &DWalletMetadata): u64 {
    dmeta.total_deposit
}

public fun public_key_type(dmeta: &DWalletMetadata): u8 {
    dmeta.public_key_type
}

public fun inactive_balances(dmeta: &DWalletMetadata, addr: address): u64 {
    if (dmeta.inactive_balances.contains(addr)) {
        dmeta.inactive_balances[addr]
    } else {
        // they don't use this wallet
        0
    }
}

public fun user_share(dmeta: &DWalletMetadata): vector<u8> {
    dmeta.user_share
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
public(package) fun create_storage(ctx: &mut TxContext): Storage {
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
        lockscript: _,
        public_key: _,
        public_key_type: _,
        user_share: _,
    } = store.dwallet_metadatas.remove(dwallet_id);
    inactive_balances.destroy_empty();
}
