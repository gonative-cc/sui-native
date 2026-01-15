module nbtc::storage;

use ika_dwallet_2pc_mpc::coordinator_inner::DWalletCap;
use nbtc::nbtc_utxo::{UtxoStore, new_utxo_store};
use sui::table::{Self, Table};

const MAX_U64: u64 = 0xFFFFFFFFFFFFFFFF;

#[error]
const EDwalletNotFound: vector<u8> = b"DWallet not found";

public struct BtcDWallet has store {
    cap: DWalletCap,
    lockscript: vector<u8>, // lock script for this dwallet
    total_deposit: u64, // total deposit balance
    public_user_share: vector<u8>, // "user share" of dwallet
    /// map user address to amount they deposit/mint
    inactive_deposits: Table<address, u64>,
}

public struct Storage has key, store {
    id: UID,
    dwallets: vector<BtcDWallet>,
    /// Store unactive / old dwallets
    dwallet_trash: Table<ID, DWalletCap>,
    utxo_store: UtxoStore,
}

// TODO: OTW for create_storage
public(package) fun create_storage(ctx: &mut TxContext): Storage {
    Storage {
        id: object::new(ctx),
        dwallets: vector<BtcDWallet>[],
        dwallet_trash: table::new<ID, DWalletCap>(ctx),
        utxo_store: new_utxo_store(ctx),
    }
}

public(package) fun create_dwallet(
    cap: DWalletCap,
    lockscript: vector<u8>,
    public_user_share: vector<u8>,
    ctx: &mut TxContext,
): BtcDWallet {
    BtcDWallet {
        cap,
        lockscript,
        total_deposit: 0,
        public_user_share,
        inactive_deposits: table::new(ctx),
    }
}

// Must not be public!
public(package) fun cap(dw: &BtcDWallet): &DWalletCap {
    &dw.cap
}

public fun lockscript(dw: &BtcDWallet): vector<u8> {
    dw.lockscript
}

public fun total_deposit(dw: &BtcDWallet): u64 {
    dw.total_deposit
}

public fun inactive_deposits(dw: &BtcDWallet, addr: address): u64 {
    if (dw.inactive_deposits.contains(addr)) {
        dw.inactive_deposits[addr]
    } else {
        // they don't use this wallet
        0
    }
}

/// Return public user share of dwallet
/// Ika don't have public api to get it onchain, this is the reason we store it in dwallet metadata
public fun public_user_share(dw: &BtcDWallet): vector<u8> {
    dw.public_user_share
}

public fun dwallet(store: &Storage, dwallet_id: ID): &BtcDWallet {
    let i = store.dwallet_idx_assert(dwallet_id);
    &store.dwallets[i]
}

// Must not be exported outside of the package!
public(package) fun dwallet_mut(store: &mut Storage, dwallet_id: ID): &mut BtcDWallet {
    let i = store.dwallet_idx_assert(dwallet_id);
    &mut store.dwallets[i]
}

// // NOTE: Never export this function publicly!
// public(package) fun dwallet_cap(store: &Storage, dwallet_id: ID): &DWalletCap {
//     let i = store.dwallet_idx_assert(dwallet_id);
//     &store.dwallets[i]
// }

// NOTE: It's OK to do linear search because we are limiting amount of dwallets to 10-20 max
/// returns MAX_U64 if the idx doesn't exist.
public(package) fun dwallet_idx(store: &Storage, dwallet_id: ID): u64 {
    let mut i = 0;
    let len = store.dwallets.length();
    while (i < len) {
        let dc = &store.dwallets[i].cap;
        if (dc.dwallet_id() == dwallet_id) return i;
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

public(package) fun add_dwallet(store: &mut Storage, d: BtcDWallet) {
    store.dwallets.push_back(d);
}

public(package) fun increase_total_deposit(store: &mut Storage, dwallet_id: ID, amount: u64) {
    let d = store.dwallet_mut(dwallet_id);
    d.total_deposit = d.total_deposit + amount;
}

// TODO: use dwallet mut ref, rather than storage
public(package) fun increase_user_balance(
    store: &mut Storage,
    dwallet_id: ID,
    user: address,
    amount: u64,
) {
    let d = store.dwallet_mut(dwallet_id);
    if (d.inactive_deposits.contains(user)) {
        let user_balance = &mut d.inactive_deposits[user];
        *user_balance = *user_balance + amount;
    } else {
        d.inactive_deposits.add(user, amount);
    };
    d.total_deposit = d.total_deposit + amount;
}

/// Removes inactive user deposit.
/// Returns the dwallet total balance after removing the user balance.
public(package) fun remove_inactive_deposit(
    store: &mut Storage,
    dwallet_id: ID,
    user: address,
): u64 {
    let d = store.dwallet_mut(dwallet_id);
    // TODO: bug: use remove
    let user_balance = &mut d.inactive_deposits[user];
    let amount = *user_balance;
    *user_balance = 0;
    d.total_deposit = d.total_deposit - amount;
    amount
}

// TODO: move the total_deposit check here (from nbtc)
/// Removes dwallet metadata and moves dwallet to the trash.
/// Aborts if the balance is not zero.
public(package) fun remove_dwallet(store: &mut Storage, dwallet_id: ID) {
    let i = store.dwallet_idx_assert(dwallet_id);
    let BtcDWallet {
        cap,
        inactive_deposits,
        total_deposit: _,
        lockscript: _,
        public_user_share: _,
    } = store.dwallets.swap_remove(i);
    inactive_deposits.destroy_empty();
    store.dwallet_trash.add(dwallet_id, cap);
}

public(package) fun utxo_store(self: &Storage): &UtxoStore {
    &self.utxo_store
}

public(package) fun utxo_store_mut(self: &mut Storage): &mut UtxoStore {
    &mut self.utxo_store
}
