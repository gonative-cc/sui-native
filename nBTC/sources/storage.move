module nbtc::storage;

use ika_dwallet_2pc_mpc::coordinator_inner::DWalletCap;
use nbtc::nbtc_utxo::{UtxoStore, new_utxo_store};
use sui::table::{Self, Table};

const MAX_U64: u64 = 0xFFFFFFFFFFFFFFFF;

#[error]
const EDwalletNotFound: vector<u8> = b"DWallet not found";

public struct DWalletMetadata has store {
    lockscript: vector<u8>, // lock script for this dwallet
    total_deposit: u64, // total deposit balance
    public_user_share: vector<u8>, // "user share" of dwallet
    /// map user address to amount they deposit/mint
    inactive_deposits: Table<address, u64>,
}

public struct Storage has key, store {
    id: UID,
    dwallets: vector<DWalletCap>,
    dwallets_meta: vector<DWalletMetadata>,
    /// Store unactive / old dwallets
    dwallet_trash: Table<ID, DWalletCap>,
    utxo_store: UtxoStore,
}

// TODO: OTW for create_storage
public(package) fun create_storage(ctx: &mut TxContext): Storage {
    Storage {
        id: object::new(ctx),
        dwallets: vector<DWalletCap>[],
        dwallets_meta: vector<DWalletMetadata>[],
        dwallet_trash: table::new<ID, DWalletCap>(ctx),
        utxo_store: new_utxo_store(ctx),
    }
}

public(package) fun create_dwallet_metadata(
    lockscript: vector<u8>,
    public_user_share: vector<u8>,
    ctx: &mut TxContext,
): DWalletMetadata {
    DWalletMetadata {
        lockscript,
        total_deposit: 0,
        public_user_share,
        inactive_deposits: table::new(ctx),
    }
}

public fun lockscript(dmeta: &DWalletMetadata): vector<u8> {
    dmeta.lockscript
}

public fun total_deposit(dmeta: &DWalletMetadata): u64 {
    dmeta.total_deposit
}

public fun inactive_deposits(dmeta: &DWalletMetadata, addr: address): u64 {
    if (dmeta.inactive_deposits.contains(addr)) {
        dmeta.inactive_deposits[addr]
    } else {
        // they don't use this wallet
        0
    }
}

/// Return public user share of dwallet
/// Ika don't have public api to get it onchain, this is the reason we store it in dwallet metadata
public fun public_user_share(dmeta: &DWalletMetadata): vector<u8> {
    dmeta.public_user_share
}

public fun dwallet_metadata(store: &Storage, dwallet_id: ID): &DWalletMetadata {
    let i = store.dwallet_idx_assert(dwallet_id);
    &store.dwallets_meta[i]
}

// NOTE: Never export this function publicly!
public(package) fun dwallet_cap(store: &Storage, dwallet_id: ID): &DWalletCap {
    let i = store.dwallet_idx_assert(dwallet_id);
    &store.dwallets[i]
}

// NOTE: It's OK to do linear search because we are limiting amount of dwallets to 10-20 max
/// returns MAX_U64 if the idx doesn't exist.
public(package) fun dwallet_idx(store: &Storage, dwallet_id: ID): u64 {
    let mut i = 0;
    let len = store.dwallets.length();
    while (i < len) {
        let d = &store.dwallets[i];
        if (d.dwallet_id() == dwallet_id) return i;
        i = i + 1;
    };
    return MAX_U64
}

/// aborts if dwallet is not found
public(package) fun dwallet_idx_assert(store: &Storage, dwallet_id: ID): u64 {
    let i = store.dwallet_idx(dwallet_id);
    if (i == MAX_U64) abort EDwalletNotFound;
    i
}

// TODO - remove, we don't need this
public(package) fun exist(store: &Storage, dwallet_id: ID): bool {
    let i = store.dwallet_idx(dwallet_id);
    i != MAX_U64
}

public(package) fun add_dwallet(store: &mut Storage, d: DWalletCap, m: DWalletMetadata) {
    store.dwallets.push_back(d);
    store.dwallets_meta.push_back(m);
}

public(package) fun increase_total_deposit(store: &mut Storage, dwallet_id: ID, amount: u64) {
    let i = store.dwallet_idx_assert(dwallet_id);
    let dm = &mut store.dwallets_meta[i];
    dm.total_deposit = dm.total_deposit + amount;
}

// TODO rename to increase_user_balance
public(package) fun increase_record_balance(
    store: &mut Storage,
    dwallet_id: ID,
    user: address,
    amount: u64,
) {
    let i = store.dwallet_idx_assert(dwallet_id);
    let dm = &mut store.dwallets_meta[i];
    if (dm.inactive_deposits.contains(user)) {
        let user_balance = &mut dm.inactive_deposits[user];
        *user_balance = *user_balance + amount;
    } else {
        dm.inactive_deposits.add(user, amount);
    };
    dm.total_deposit = dm.total_deposit + amount;
}

/// Removes inactive user deposit.
/// Returns the dwallet total balance after removing the user balance.
public(package) fun remove_inactive_deposit(
    store: &mut Storage,
    dwallet_id: ID,
    user: address,
): u64 {
    let i = store.dwallet_idx_assert(dwallet_id);
    let dm = &mut store.dwallets_meta[i];
    // TODO: bug: use remove
    let user_balance = &mut dm.inactive_deposits[user];
    let amount = *user_balance;
    *user_balance = 0;
    dm.total_deposit = dm.total_deposit - amount;
    amount
}

/// Removes dwallet metadata and moves dwallet to the trash.
/// Aborts if the balance is not zero.
public(package) fun remove_dwallet(store: &mut Storage, dwallet_id: ID) {
    let i = store.dwallet_idx_assert(dwallet_id);
    let DWalletMetadata {
        inactive_deposits,
        total_deposit: _,
        lockscript: _,
        public_user_share: _,
    } = store.dwallets_meta.swap_remove(i);
    inactive_deposits.destroy_empty();
    let d = store.dwallets.swap_remove(i);
    store.dwallet_trash.add(dwallet_id, d);
}

public(package) fun utxo_store(self: &Storage): &UtxoStore {
    &self.utxo_store
}

public(package) fun utxo_store_mut(self: &mut Storage): &mut UtxoStore {
    &mut self.utxo_store
}
