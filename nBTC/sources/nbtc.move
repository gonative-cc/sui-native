// SPDX-License-Identifier: MPL-2.0

module nbtc::nbtc;

use bitcoin_executor::utxo::{OutPoint, Data as UTXOData};
use bitcoin_parser::reader;
use bitcoin_parser::tx;
use bitcoin_spv::light_client::LightClient;
use ika::ika::IKA;
use ika_dwallet_2pc_mpc::coordinator::{request_sign, DWalletCoordinator};
use ika_dwallet_2pc_mpc::coordinator_inner::{VerifiedPresignCap, DWalletCap};
use ika_dwallet_2pc_mpc::sessions_manager::SessionIdentifier;
use nbtc::verify_payment::verify_payment;
use sui::address;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin, TreasuryCap};
use sui::event;
use sui::sui::SUI;
use sui::table::{Self, Table};
use sui::url;

//
// Constant
//

/// Package version
const VERSION: u32 = 1;

/// Coin Metadata
const DECIMALS: u8 = 8;
const SYMBOL: vector<u8> = b"nBTC-v0.3";
const NAME: vector<u8> = b"Native nBTC v0.3";
const DESCRIPTION: vector<u8> = b"Native synthetic BTC";
const ICON_URL: vector<u8> =
    b"https://raw.githubusercontent.com/gonative-cc/sui-native/master/assets/nbtc.svg";

/// ops_arg consts
const MINT_OP_APPLY_FEE: u32 = 1;

const ECDSA: u32 = 0;
const SHA256: u32 = 1;

/// One Time Witness
public struct NBTC has drop {}

//
// Errors
//

#[error]
const EInvalidDepositKey: vector<u8> = b"Not an nBTC deposit spend key";
#[error]
const ETxAlreadyUsed: vector<u8> = b"The Bitcoin transaction ID has been already used for minting";
#[error]
const EMintAmountIsZero: vector<u8> = b"BTC deposit must not be zero";
#[error]
const EUntrustedLightClient: vector<u8> = b"Wrong Light Client object ID";
#[error]
const EVersionMismatch: vector<u8> = b"The package has been updated. You are using a wrong version";
#[error]
const EAlreadyUpdated: vector<u8> =
    b"The package version has been already updated to the latest one";
#[error]
const EInvalidOpsArg: vector<u8> = b"invalid mint ops_arg";
#[error]
const EDuplicatedKey: vector<u8> = b"duplicated key";
#[error]
const EBalanceNotEmpty: vector<u8> = b"balance not empty";

//
// Structs
//

/// Operator capability. Created only once in the `init` function.
public struct OpCap has key, store { id: UID }

/// Admin capability. Created only once in the `init` function.
/// It has higher capabilities than Operator. For example, it can change contract parameters .
public struct AdminCap has key, store { id: UID }

/// NbtcContract holds the TreasuryCap as well as configuration and state.
/// It should be a shared object to enable anyone to interact with the contract.
public struct NbtcContract has key, store {
    id: UID,
    version: u32,
    cap: TreasuryCap<NBTC>,
    /// set of "minted" txs
    tx_ids: Table<vector<u8>, bool>,
    // Bitcoin light client
    bitcoin_lc: ID,
    fallback_addr: address,
    // TODO: change to taproot once Ika will support it
    /// Active "user shard" of the bitcoin private key.
    bitcoin_spend_key: vector<u8>,
    /// BTC balances for the current bitcoin_spend_key.
    active_balance: u64,
    // TODO: consider using Table for inactive_spend_keys and inactive_balances
    /// If user, by mistake, will use inactive spend key, then we should protect from a BTC deadlock
    /// in that account. In such case we don't mint nBTC, but we allow the user to transfer it back.
    /// Keys can be removed and the order is not guaranteed to be same as the insertion order.
    inactive_spend_keys: vector<vector<u8>>,
    /// Maps (bitcoin deposit key ++ user address) to its BTC deposit (in case he deposited to an
    /// inactive key from the list above).
    inactive_user_balances: Table<vector<u8>, u64>,
    /// total balance per inactive key, indexed accordingly to inactive_spend_keys.
    inactive_balances: vector<u64>,
    /// as in Balance<nBTC>
    mint_fee: u64,
    fees_collected: Balance<NBTC>,
    utxos: Table<OutPoint, UTXOData>,
    // mapping a spend_key to related dWallet cap for issue signature
    dwallet_caps: Table<vector<u8>, DWalletCap>,
    // TODO: probably we should have UTXOs / nbtc pubkey
    utxos: Table<u64, Utxo>,
    next_utxo: u64,
    redeem_requests: Table<u64, RedeemRequest>,
    next_redeem_req: u64,
}

// TODO: we need to store them by owner (the nBTC key)?
public struct Utxo has store {
    tx_id: u256, // TODO: this is 32-byte hash. we can also use vector<u8>
    vout: u32,
    value: u64,
}

public enum RedeemStatus has copy, drop, store {
    Resolving, // finding the best UTXOs
    Signing,
    Signed,
    Confirmed,
}

public struct RedeemRequest has store {
    // TODO: maybe we don't need the ID?
    id: UID,
    redeemer: address, // TODO: maybe it's not needed
    /// Bitcoin spent key (address)
    recipient: vector<u8>,
    status: RedeemStatus,
    amount: u64,
    inputs: vector<Utxo>,
    remainder_output: Utxo,
}

/// MintEvent is emitted when nBTC is successfully minted.
public struct MintEvent has copy, drop {
    /// Sui recipient
    recipient: address,
    amount: u64, // in satoshi
    fee: u64,
    // TODO: maybe we should change to bitcoin address format?
    bitcoin_spend_key: vector<u8>,
    btc_tx_id: vector<u8>,
}

public struct InactiveDepositEvent has copy, drop {
    bitcoin_spend_key: vector<u8>,
    recipient: address,
    amount: u64, // in satoshi
}

public struct RedeemInactiveDepositEvent has copy, drop {
    bitcoin_spend_key: vector<u8>,
    /// Bitcoin recipient
    recipient: vector<u8>,
    amount: u64, // in satoshi
}

//
// Functions
//

fun init(witness: NBTC, ctx: &mut TxContext) {
    let (treasury_cap, metadata) = coin::create_currency<NBTC>(
        witness,
        DECIMALS,
        SYMBOL,
        NAME,
        DESCRIPTION,
        option::some(url::new_unsafe_from_bytes(ICON_URL)),
        ctx,
    );

    // NOTE: we removed post deployment setup function and didn't want to implement PTB style
    // initialization, so we require setting the address before publishing the package.
    let bitcoin_spend_key = b""; // TODO: valid bitcoin address
    assert!(bitcoin_spend_key.length() >= 22);
    transfer::public_freeze_object(metadata);
    let contract = NbtcContract {
        id: object::new(ctx),
        version: VERSION,
        cap: treasury_cap,
        tx_ids: table::new<vector<u8>, bool>(ctx),
        bitcoin_lc: @bitcoin_lc.to_id(),
        fallback_addr: @fallback_addr,
        bitcoin_spend_key,
        active_balance: 0,
        inactive_spend_keys: vector[],
        inactive_user_balances: table::new(ctx),
        inactive_balances: vector[],
        mint_fee: 10,
        utxos: table::new(ctx),
        dwallet_caps: table::new(ctx),
        fees_collected: balance::zero(),
        utxos: table::new<u64, Utxo>(ctx),
        next_utxo: 0,
        redeem_requests: table::new<u64, RedeemRequest>(ctx),
        next_redeem_req: 0,
    };
    transfer::public_share_object(contract);

    transfer::transfer(
        OpCap { id: object::new(ctx) },
        ctx.sender(),
    );
    transfer::transfer(
        AdminCap { id: object::new(ctx) },
        ctx.sender(),
    );
}

//
// Helper methods
//

/// make all checks. Returns (Sui recipient, amount) tuple.
/// See mint function for documentation about parameters.
fun verify_deposit(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    deposit_spend_key: vector<u8>,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    // see mint function for information about payload argument.
    _payload: vector<u8>,
    ops_arg: u32,
): (u64, address) {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(ops_arg == 0 || ops_arg == MINT_OP_APPLY_FEE, EInvalidOpsArg);
    let provided_lc_id = object::id(light_client);
    assert!(provided_lc_id == contract.get_light_client_id(), EUntrustedLightClient);

    let mut r = reader::new(tx_bytes);
    let tx = tx::deserialize(&mut r);

    let tx_id = tx.tx_id();

    // Double spend prevent
    assert!(!contract.tx_ids.contains(tx_id), ETxAlreadyUsed);
    contract.tx_ids.add(tx_id, true);
    // NOTE: We assume only one active key. We should handle mutiple nbtc active key in the
    // future.
    let (amount, mut op_return) = verify_payment(
        light_client,
        height,
        proof,
        tx_index,
        &tx,
        deposit_spend_key,
    );

    assert!(amount > 0, EMintAmountIsZero);
    let mut recipient: address = contract.get_fallback_addr();
    if (op_return.is_some()) {
        let msg = op_return.extract();
        let mut msg_reader = reader::new(msg);
        let op_ret_type = msg_reader.read_byte();
        if (op_ret_type == 0x00) {
            if (msg_reader.readable(32)) {
                recipient = address::from_bytes(msg_reader.read(32));
            };

            // For op_ret_type=0x0 we expect only 32 bytes. If the stream is longer (more data), then
            // the format is invalid, so moving recipient to fallback.
            if (!msg_reader.end_stream()) {
                recipient = contract.get_fallback_addr();
            }
        }
    };

    // TODO: extract and record UTXOs
    let utxo_idx = contract.next_utxo;
    contract.next_utxo = contract.next_utxo + 1;

    (amount, recipient)
}

/// returns idx of key in in `inactive_spend_keys` or None if the key is not there.
public(package) fun inactive_key_idx(contract: &NbtcContract, key: vector<u8>): Option<u64> {
    let mut i = contract.inactive_spend_keys.length();
    if (i ==0) return option::none();
    i = i-1;
    while (i >= 0) {
        if (contract.inactive_spend_keys[i] == key) return option::some(i);
        i = i -1;
    };
    option::none()
}

fun inactive_bal_key(deposit_spend_key: &vector<u8>, recipient: address): vector<u8> {
    let mut bal_key = *deposit_spend_key; // makes a copy
    // collistion is not possible, because recipient is constant size
    bal_key.append(recipient.to_bytes());
    bal_key
}

//
// Public methods
//

/// Mints nBTC tokens after verifying a Bitcoin transaction proof.
/// * `tx_bytes`: raw, hex-encoded tx bytes.
/// * `proof`: merkle proof for the tx.
/// * `height`: block height, where the tx was included.
/// * `tx_index`: index of the tx within the block.
/// * `payload`: additional argument for the op_return instruction handling.
/// * `ops_arg`: operation argument controlling fee application.
///   - Pass `1` to apply minting fees.
///   - Pass `0` to skip minting fees (for special cases or admin operations).
/// Emits `MintEvent` if successful.
public fun mint(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    // The `payload` parameter is reserved for advanced op_return instruction handling.
    // Implementation pending. Do not remove; will be used to support additional minting logic,
    // while keeping stable API.
    payload: vector<u8>,
    ops_arg: u32,
    ctx: &mut TxContext,
) {
    let spend_key = contract.bitcoin_spend_key;
    let (mut amount, recipient) = contract.verify_deposit(
        light_client,
        spend_key,
        tx_bytes,
        proof,
        height,
        tx_index,
        payload,
        ops_arg,
    );
    assert!(amount > 0, EMintAmountIsZero);

    contract.active_balance = contract.active_balance + amount;

    let mut minted = contract.cap.mint_balance(amount);
    let mut fee_amount = 0;

    if (ops_arg == MINT_OP_APPLY_FEE) {
        fee_amount = amount.min(contract.mint_fee);
        let fee = minted.split(fee_amount);
        amount = amount - fee_amount;
        contract.fees_collected.join(fee);
    };

    if (amount > 0) transfer::public_transfer(coin::from_balance(minted, ctx), recipient)
    else minted.destroy_zero();

    event::emit(MintEvent {
        recipient,
        amount,
        fee: fee_amount,
        bitcoin_spend_key: spend_key,
        // TODO: utxo_idx,
        btc_tx_id: vector[], // TODO: construct tx_id
    });
}

// TODO: test this function
/// Like mint, but records deposit to an inacitve deposit_spend_key.
/// This function allows user to record and verify deposit to an inactive key (e.g. user
/// by mistake used an old, inactive bitcoin deposit key) and recover that using
/// `redeem_from_inactive` function call.
/// Arguments are same as to `mint` with one extra argument:
/// * `deposit_spend_key`: bitcoin spend pub key the user used for the UTXO nBTC deposit.
/// Emits `InactiveDepositEvent`.
public fun record_inactive_deposit(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    payload: vector<u8>,
    ops_arg: u32,
    deposit_spend_key: vector<u8>,
) {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(ops_arg == 0 || ops_arg == MINT_OP_APPLY_FEE, EInvalidOpsArg);
    let provided_lc_id = object::id(light_client);
    assert!(provided_lc_id == contract.get_light_client_id(), EUntrustedLightClient);
    let mut inactive_key_idx = contract.inactive_key_idx(deposit_spend_key);
    assert!(inactive_key_idx.is_some(), EInvalidDepositKey);

    let (amount, recipient) = contract.verify_deposit(
        light_client,
        deposit_spend_key,
        tx_bytes,
        proof,
        height,
        tx_index,
        payload,
        ops_arg,
    );

    let key_idx = inactive_key_idx.extract();
    let bal = &mut contract.inactive_balances[key_idx];
    *bal = *bal + amount;

    let bal_key = inactive_bal_key(&deposit_spend_key, recipient);
    if (contract.inactive_user_balances.contains(bal_key)) {
        let user_bal = &mut contract.inactive_user_balances[bal_key];
        *user_bal = *user_bal + amount;
    } else {
        contract.inactive_user_balances.add(bal_key, amount);
    };
    event::emit(InactiveDepositEvent {
        bitcoin_spend_key: deposit_spend_key,
        recipient,
        amount,
    });
}

/// message: payload should sign by Ika
/// public_nbtc_signature the signature sign by public nbtc dwallet
/// session_identifier: signing session for this sign request.
/// payment_ika and payment_sui require for create for signature on Ika.
/// Ika reponse this request asynchronous in other tx
public(package) fun request_signature(
    contract: &NbtcContract,
    dwallet_coordinator: &mut DWalletCoordinator,
    presign_cap: VerifiedPresignCap,
    message: vector<u8>,
    public_nbtc_signature: vector<u8>,
    session_identifier: SessionIdentifier,
    payment_ika: &mut Coin<IKA>,
    payment_sui: &mut Coin<SUI>,
    ctx: &mut TxContext,
) {
    // TODO: Handle case Ika send token back to user if we paid more than require fee.
    // TODO: Verify dwallet_coordinator corrent coordinator of Ika
    let spend_key = contract.bitcoin_spend_key;
    let dwallet_cap = &contract.dwallet_caps[spend_key];
    let message_approval = dwallet_coordinator.approve_message(dwallet_cap, ECDSA, SHA256, message);
    dwallet_coordinator.request_sign(
        presign_cap,
        message_approval,
        public_nbtc_signature,
        session_identifier,
        payment_ika,
        payment_sui,
        ctx,
    );
}

/// redeem initiates nBTC redemption and BTC withdraw process.
/// Returns total amount of redeemed balance.
public fun redeem(
    contract: &mut NbtcContract,
    coins: vector<Coin<NBTC>>,
    _bitcoin_recipient: vector<u8>,
    _ctx: &mut TxContext,
): u64 {
    assert!(contract.version == VERSION, EVersionMismatch);
    // TODO: implement logic to guard burning and manage UTXOs
    // TODO: we can call remove_inactive_spend_key if reserves of this key is zero
    coins.fold!(0, |total, c| total + coin::burn(&mut contract.cap, c))
}

// TODO: Implement logic for generate the redeem transaction data
// This can be offchain or onchain depends on algorithm we design.
public fun btc_redeem_tx(): vector<u8> {
    b"Go Go Native"
}

/// Allows user to withdraw back deposited BTC that used an inactive deposit spend key.
/// When user deposits to an inactive Bitcoin key, nBTC is not minted.
/// See docs of the record_inactive_deposit function.
public fun withdraw_inactive_deposit(
    contract: &mut NbtcContract,
    bitcoin_recipient: vector<u8>,
    deposit_spend_key: vector<u8>,
    ctx: &mut TxContext,
): u64 {
    assert!(contract.version == VERSION, EVersionMismatch);
    let mut inactive_key_idx = contract.inactive_key_idx(deposit_spend_key);
    assert!(inactive_key_idx.is_some(), EInvalidDepositKey);
    let sender = ctx.sender();
    let key_idx = inactive_key_idx.extract();
    let mut bal_key = deposit_spend_key; // makes a copy
    bal_key.append(sender.to_bytes());
    let amount = contract.inactive_user_balances.remove(bal_key);
    let total_bal = &mut contract.inactive_balances[key_idx];
    *total_bal = *total_bal - amount;

    event::emit(RedeemInactiveDepositEvent {
        bitcoin_spend_key: deposit_spend_key,
        recipient: bitcoin_recipient,
        amount,
    });

    // TODO: implement logic to guard burning
    // TODO: we can delete the btc public key when reserves of this key is zero

    amount
}

/// update_version updates the contract.version to the latest, making the usage of the older
/// versions not possible
public fun update_version(contract: &mut NbtcContract) {
    assert!(VERSION > contract.version, EAlreadyUpdated);
    contract.version = VERSION;
}

/// Merge existing UTXOs to a new, aggregated one assigned to the current active spend key.
/// Used for moving funds from an inactive spend key to an active one.
public fun merge_utxos(_: &mut NbtcContract, _num_utxos: u16) {}

//
// Admin functions
//

public fun withdraw_fees(_: &OpCap, contract: &mut NbtcContract, ctx: &mut TxContext): Coin<NBTC> {
    coin::from_balance(contract.fees_collected.withdraw_all(), ctx)
}

public fun change_fees(_: &AdminCap, contract: &mut NbtcContract, mint_fee: u64) {
    contract.mint_fee = mint_fee;
}

/// Set a dwallet_cap for related BTC spend_key.
/// BTC spend_key must derive from dwallet public key which is control by dwallet_cap.
public fun add_dwallet_cap(
    _: &AdminCap,
    contract: &mut NbtcContract,
    spend_key: vector<u8>,
    dwallet_cap: DWalletCap,
) {
    // TODO: Verify spend_key derive from dwallet public key
    contract.dwallet_caps.add(spend_key, dwallet_cap);
}

/// Set btc endpoint for deposit on nBTC, and set reserve of this endpoint is zero.
/// In the case, we use this key before we will enable deposit endpoint again.
public fun add_spend_key(_: &AdminCap, contract: &mut NbtcContract, key: vector<u8>) {
    let key_idx = contract.inactive_key_idx(key);
    assert!(contract.bitcoin_spend_key != key && key_idx.is_none(), EDuplicatedKey);

    contract.inactive_spend_keys.push_back(contract.bitcoin_spend_key);
    contract.bitcoin_spend_key = key;
    contract.inactive_balances.push_back(contract.active_balance);
    contract.active_balance = 0;
}

public fun remove_inactive_spend_key(_: &AdminCap, contract: &mut NbtcContract, key_idx: u64) {
    // TODO: need to decide if we want to keep balance check. Technically, it's not needed
    // if we can provide public signature to the merge_coins
    // NOTE: we don't check inactive_user_balance here because this is out of our control and the
    // spend key is recorded as a part of the Table key.

    assert!(contract.inactive_balances.length() > key_idx, EInvalidDepositKey);
    assert!(contract.inactive_balances[key_idx] == 0, EBalanceNotEmpty);
    contract.inactive_balances.swap_remove(key_idx);
    contract.inactive_spend_keys.swap_remove(key_idx);
}

//
// View functions
//

public fun utxos(contract: &NbtcContract): &Table<OutPoint, UTXOData> {
    &contract.utxos
}

public fun total_supply(contract: &NbtcContract): u64 {
    coin::total_supply(&contract.cap)
}

public fun get_light_client_id(contract: &NbtcContract): ID {
    contract.bitcoin_lc
}

public fun get_fallback_addr(contract: &NbtcContract): address {
    contract.fallback_addr
}

public fun get_mint_fee(contract: &NbtcContract): u64 {
    contract.mint_fee
}

public fun active_balance(contract: &NbtcContract): u64 {
    contract.active_balance
}

// TODO: we should also have bitcoin spend key address
public fun bitcoin_spend_key(contract: &NbtcContract): vector<u8> {
    contract.bitcoin_spend_key
}

/// from: the index of the first key to include in the returned list. If it's >= length of the
///    inactive keys list, then empty list is returned.
/// to: the index of the first key to exclude from the returned list. If it's 0 then
///    the length of the inactive keys list is used.
public fun inactive_spend_keys(contract: &NbtcContract, from: u64, to: u64): vector<vector<u8>> {
    let len = contract.inactive_spend_keys.length();
    if (from >= len) return vector[];
    let to = if (to == 0 || to > len) len else to;
    vector::tabulate!(to-from, |i| contract.inactive_spend_keys[from+i])
}

//
// Testing
//

#[test_only]
public(package) fun init_for_testing(
    bitcoin_lc: address,
    fallback_addr: address,
    nbtc_bitcoin_spend_key: vector<u8>,
    ctx: &mut TxContext,
): NbtcContract {
    let witness = NBTC {};
    let (contract_cap, metadata) = coin::create_currency<NBTC>(
        witness,
        DECIMALS,
        SYMBOL,
        NAME,
        DESCRIPTION,
        option::some(url::new_unsafe_from_bytes(ICON_URL)),
        ctx,
    );
    transfer::public_freeze_object(metadata);
    let contract = NbtcContract {
        id: object::new(ctx),
        version: VERSION,
        cap: contract_cap,
        tx_ids: table::new<vector<u8>, bool>(ctx),
        bitcoin_lc: bitcoin_lc.to_id(),
        fallback_addr,
        bitcoin_spend_key: nbtc_bitcoin_spend_key,
        active_balance: 0,
        inactive_spend_keys: vector[],
        inactive_user_balances: table::new(ctx),
        inactive_balances: vector[],
        fees_collected: balance::zero(),
        utxos: table::new(ctx),
        mint_fee: 10,
        dwallet_caps: table::new(ctx),
        redeem_requests: table::new(ctx),
        utxos: table::new(ctx),
        next_redeem_req: 0,
        next_utxo: 0,
    };
    contract
}

#[test_only]
public fun get_fees_collected(contract: &NbtcContract): u64 {
    contract.fees_collected.value()
}

#[test_only]
public(package) fun set_utxo(contract: &mut NbtcContract, outpoint: OutPoint, data: UTXOData) {
    contract.utxos.add(outpoint, data)
}
