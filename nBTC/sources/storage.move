module nbtc::storage;

use bitcoin_lib::script::verify_script_merkle_proof;
use ika_dwallet_2pc_mpc::coordinator_inner::DWalletCap;
use nbtc::nbtc_utxo::{UtxoStore, new_utxo_store};
use std::string::String;
use sui::table::{Self, Table};

const MAX_U64: u64 = 0xFFFFFFFFFFFFFFFF;

#[error]
const EDwalletNotFound: vector<u8> = b"DWallet not found";
#[error]
const EDwalletByBtcAddrNotFound: vector<u8> = b"DWallet with btcaddr not found";
#[error]
const ENoDwalletInStore: vector<u8> = b"dwallets list is empty";

public struct BtcDWallet has store {
    cap: DWalletCap,
    lockscript: vector<u8>, // lock script for this dwallet
    control_byte: u8, // Taproot control byte for script path spending
    script_merkle_root: vector<u8>, // Taproot script merkle root (32 bytes)
    total_deposit: u64, // total deposit balance
    user_key_share: vector<u8>, // "user share" of dwallet
    /// map user address to amount they deposit/mint
    inactive_deposits: Table<address, u64>,
    btcaddr: String, // bitcoin address for this dwallet
}

public struct Storage has key, store {
    id: UID,
    dwallets: vector<BtcDWallet>,
    /// Store unactive / old dwallets
    dwallet_trash: Table<ID, BtcDWallet>,
    utxo_store: UtxoStore,
}

// TODO: OTW for create_storage
public(package) fun create_storage(ctx: &mut TxContext): Storage {
    Storage {
        id: object::new(ctx),
        dwallets: vector<BtcDWallet>[],
        dwallet_trash: table::new(ctx),
        utxo_store: new_utxo_store(ctx),
    }
}

public(package) fun create_dwallet(
    cap: DWalletCap,
    lockscript: vector<u8>,
    control_byte: u8,
    script_merkle_root: vector<u8>,
    user_key_share: vector<u8>,
    btcaddr: String,
    ctx: &mut TxContext,
): BtcDWallet {
    BtcDWallet {
        cap,
        lockscript,
        control_byte,
        script_merkle_root,
        total_deposit: 0,
        user_key_share,
        inactive_deposits: table::new(ctx),
        btcaddr,
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
public fun user_key_share(dw: &BtcDWallet): vector<u8> {
    dw.user_key_share
}

/// Return Taproot control byte for script path spending
public fun control_byte(dw: &BtcDWallet): u8 {
    dw.control_byte
}

/// Return Taproot script merkle root (32 bytes)
public fun script_merkle_root(dw: &BtcDWallet): vector<u8> {
    dw.script_merkle_root
}

/// Verifies that a Taproot leaf hash belongs to the dWallet's script merkle tree.
/// Verifies the provided leaf hash against the dWallet's script_merkle_root
/// using the provided merkle proof path.
///
/// # Arguments
/// * `dwallet` - The dWallet containing the script_merkle_root
/// * `leaf_hash` - The TapLeaf hash to verify (32 bytes)
/// * `merkle_path` - Vector of sibling hashes from leaf to root (ordered from leaf level upward)
///
/// # Returns
/// * `true` if the leaf hash is in the dWallet's merkle tree
/// * `false` otherwise
/// ```
public fun verify_taproot_script(
    dwallet: &BtcDWallet,
    leaf_hash: vector<u8>,
    merkle_path: vector<vector<u8>>,
): bool {
    verify_script_merkle_proof(
        leaf_hash,
        merkle_path,
        dwallet.script_merkle_root,
    )
}

public fun is_inactive(store: &Storage, dwallet_id: ID): bool {
    store.dwallet_trash.contains(dwallet_id)
}

// NOTE: It's OK to do linear search because we are limiting amount of dwallets to 10-20 max
/// returns MAX_U64 if the idx doesn't exist.
fun dwallet_idx(store: &Storage, dwallet_id: ID): u64 {
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
fun dwallet_idx_assert(store: &Storage, dwallet_id: ID): u64 {
    let i = store.dwallet_idx(dwallet_id);
    if (i == MAX_U64) abort EDwalletNotFound;
    i
}

public(package) fun exist(store: &Storage, dwallet_id: ID): bool {
    let i = store.dwallet_idx(dwallet_id);
    i != MAX_U64
}

public fun dwallet(store: &Storage, dwallet_id: ID): &BtcDWallet {
    if (store.is_inactive(dwallet_id)) {
        return store.inactive_dwallet(dwallet_id)
    };
    let i = store.dwallet_idx_assert(dwallet_id);
    &store.dwallets[i]
}

public fun dwallet_id(btcDwallet: &BtcDWallet): ID {
    btcDwallet.cap.dwallet_id()
}

/// Returns the ID of the current active dwallet (last element in the vector).
/// Aborts if no dwallet has been set as active.
public fun recommended_dwallet(store: &Storage): &BtcDWallet {
    assert!(!store.dwallets.is_empty(), ENoDwalletInStore);
    let dwallet = &store.dwallets[store.dwallets.length() - 1];
    dwallet
}

/// Returns ID of dwallet by bitcoin address.
/// Searches active dwallets.
/// Aborts if not found.
public fun dwallet_id_by_addr(store: &Storage, addr: String): ID {
    let idx = vector::find_index!(&store.dwallets, |dw: &BtcDWallet| {
        dw.btcaddr == addr
    });
    assert!(option::is_some(&idx), EDwalletByBtcAddrNotFound);
    store.dwallets[option::destroy_some(idx)].cap.dwallet_id()
}

/// Returns an inactive dwallet by ID.
/// Aborts if dwallet is not inactive.
public fun inactive_dwallet(store: &Storage, dwallet_id: ID): &BtcDWallet {
    assert!(store.dwallet_trash.contains(dwallet_id), EDwalletNotFound);
    &store.dwallet_trash[dwallet_id]
}

// returns mutable reference to an active dwallet.
// NOTE: Must not be exported outside of the package!
public(package) fun dwallet_mut(store: &mut Storage, dwallet_id: ID): &mut BtcDWallet {
    let i = store.dwallet_idx_assert(dwallet_id);
    &mut store.dwallets[i]
}

// Must not be exported outside of the package!
public(package) fun dwallet_mut_inactive(store: &mut Storage, dwallet_id: ID): &mut BtcDWallet {
    assert!(store.dwallet_trash.contains(dwallet_id), EDwalletNotFound);
    table::borrow_mut(&mut store.dwallet_trash, dwallet_id)
}

public(package) fun add_dwallet(store: &mut Storage, d: BtcDWallet) {
    store.dwallets.push_back(d);
}

public(package) fun deactivate_dwallet(store: &mut Storage, dwallet_id: ID) {
    let i = store.dwallet_idx_assert(dwallet_id);
    let dwallet = store.dwallets.remove(i);
    let dwallet_id = dwallet.cap.dwallet_id();
    store.dwallet_trash.add(dwallet_id, dwallet);
}

public(package) fun increase_total_deposit(store: &mut Storage, dwallet_id: ID, amount: u64) {
    let d = store.dwallet_mut(dwallet_id);
    d.total_deposit = d.total_deposit + amount;
}

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

/// Returns the dwallet total balance after removing the user balance.
public(package) fun remove_inactive_user_deposit(
    store: &mut Storage,
    dwallet_id: ID,
    user: address,
): u64 {
    let d = store.dwallet_mut_inactive(dwallet_id);
    let amount = d.inactive_deposits.remove(user);
    d.total_deposit = d.total_deposit - amount;
    amount
}

public(package) fun utxo_store(self: &Storage): &UtxoStore {
    &self.utxo_store
}

public(package) fun utxo_store_mut(self: &mut Storage): &mut UtxoStore {
    &mut self.utxo_store
}
