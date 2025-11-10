// SPDX-License-Identifier: MPL-2.0

module nbtc::nbtc;

use bitcoin_lib::encoding::u64_to_le_bytes;
use bitcoin_lib::reader;
use bitcoin_lib::sighash::{create_segwit_preimage, create_p2wpkh_scriptcode};
use bitcoin_lib::tx;
use bitcoin_spv::light_client::LightClient;
use ika::ika::IKA;
use ika_dwallet_2pc_mpc::coordinator::{request_sign, DWalletCoordinator};
use ika_dwallet_2pc_mpc::coordinator_inner::{
    VerifiedPresignCap,
    DWalletCap,
    VerifiedPartialUserSignatureCap
};
use ika_dwallet_2pc_mpc::sessions_manager::SessionIdentifier;
use nbtc::nbtc_utxo::{Self, Utxo};
use nbtc::sign_request::{Self, RedeemRequest};
use nbtc::verify_payment::verify_payment;
use sui::address;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin, TreasuryCap};
use sui::event;
use sui::sui::SUI;
use sui::table::{Self, Table};
use sui::url;
use sui::vec_map::{Self, VecMap};

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
#[error]
const ENotReadlyForSign: vector<u8> = b"redeem tx is not ready for signing";
#[error]
const EInputAlredyUsed: vector<u8> = b"this input has been already used in other signature request";
#[error]
const EInvalidSignId: vector<u8> = b"invalid sign id for redeem request";
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
    // mapping a spend_key to related dWallet cap for issue signature
    dwallet_caps: Table<vector<u8>, DWalletCap>,
    // mapping dwallet id to public key
    dwallet_pks: Table<ID, vector<u8>>,
    // TODO: probably we should have UTXOs / nbtc pubkey
    utxos: Table<u64, Utxo>,
    next_utxo: u64,
    // redeem request token for nbtc
    redeem_requests: Table<u64, RedeemRequest>,
    // lock nbtc for redeem, this is a mapping from request id to nBTC redeem coin
    locked: Table<u64, Coin<NBTC>>,
    next_redeem_req: u64,
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
    utxo_idx: vector<u64>,
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
        dwallet_pks: table::new(ctx),
        fees_collected: balance::zero(),
        next_utxo: 0,
        redeem_requests: table::new<u64, RedeemRequest>(ctx),
        locked: table::new(ctx),
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

/// make all checks. Returns (amount, recipient, utxo_idx) tuple.
/// See mint function for documentation about parameters.
/// TODO: Support multiple UTXOs with the same spending_key in a single transaction.
/// Currently only handles one UTXO per transaction. Ideally there should be only one
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
): (u64, address, vector<u64>) {
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
    let (amount, mut op_return, vouts) = verify_payment(
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

    // UTXO for each matched output since vouts is a vector now
    let o = tx.outputs();
    let mut utxo_idx = vector[];
    let mut i = 0;
    while (i < vouts.length()) {
        let vout_idx = vouts[i];
        let o_amount = o[vout_idx as u64].amount();
        let utxo_idx_next = contract.next_utxo;
        add_utxo_to_contract(contract, tx_id, vout_idx, o_amount);
        utxo_idx.push_back(utxo_idx_next);
        i = i + 1;
    };

    (amount, recipient, utxo_idx)
}

/// returns idx of key in in `inactive_spend_keys` or None if the key is not there.
public(package) fun inactive_key_idx(contract: &NbtcContract, key: vector<u8>): Option<u64> {
    contract.inactive_spend_keys.find_index!(|inactive_spend_key| {
        inactive_spend_key == key
    })
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
    let (mut amount, recipient, utxo_idx) = contract.verify_deposit(
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
        btc_tx_id: vector[], // tx_id is stored in the UTXO itself
        utxo_idx,
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

    let (amount, recipient, _utxo_idx) = contract.verify_deposit(
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

/// Request signing for specific input in redeem transaction,
/// partial_user_signature_cap: Created by future sign request
/// Because we use shared dwallet this is already public and we don't need to send "user share's"
/// signarure. The Ika also auto checks if the message we want to sign is identical between messages
/// signed by nbtc user share and message we request here.
/// We will:
///  - compute the sign hash for specific input
///  - Request signature from Ika
///  - Record sing_id and other recomputeable data
public fun request_signature_for_input(
    contract: &mut NbtcContract,
    dwallet_coordinator: &mut DWalletCoordinator,
    request_id: u64,
    input_idx: u32,
    user_sig_cap: VerifiedPartialUserSignatureCap,
    session_identifier: SessionIdentifier,
    payment_ika: &mut Coin<IKA>,
    payment_sui: &mut Coin<SUI>,
    ctx: &mut TxContext,
) {
    let request = &mut contract.redeem_requests[request_id];
    assert!(request.status().is_signing(), ENotReadlyForSign);
    assert!(request.has_signature(input_idx), EInputAlredyUsed);

    // This should include other information for create sign hash
    let sign_hash = request.sig_hash(input_idx);

    let spend_key = contract.bitcoin_spend_key;
    let dwallet_cap = &contract.dwallet_caps[spend_key];
    let message_approval = dwallet_coordinator.approve_message(
        dwallet_cap,
        ECDSA,
        SHA256,
        sign_hash,
    );

    let sign_id = dwallet_coordinator.request_sign_with_partial_user_signature_and_return_id(
        user_sig_cap,
        message_approval,
        session_identifier,
        payment_ika,
        payment_sui,
        ctx,
    );

    request.set_sign_request_metadata(input_idx, sign_hash, sign_id);
}

/// redeem initiates nBTC redemption and BTC withdraw process.
/// Returns total amount of redeemed balance.
public fun redeem(
    contract: &mut NbtcContract,
    coin: Coin<NBTC>,
    recipient_script: vector<u8>,
    ctx: &mut TxContext,
): u64 {
    assert!(contract.version == VERSION, EVersionMismatch);
    // TODO: implement logic to guard burning and manage UTXOs
    // TODO: we can call remove_inactive_spend_key if reserves of this key is zero

    let r = sign_request::new(
        contract.bitcoin_spend_key,
        ctx.sender(),
        recipient_script,
        coin.value(),
        150, // TODO: query fee from oracle or give api for user to set this
        ctx,
    );
    // TODO: we repeat this logic a lot of time. Consider to create a generic function for this
    // type.
    let redeem_id = contract.next_redeem_req;
    contract.redeem_requests.add(redeem_id, r);
    contract.locked.add(redeem_id, coin);
    contract.next_redeem_req = redeem_id + 1;

    return redeem_id
}

// TODO: Implement logic for generate the redeem transaction data
// This can be offchain or onchain depends on algorithm we design.
public fun btc_redeem_tx(): vector<u8> {
    b"Go Go Native"
}

public(package) fun validate_signature(
    contract: &mut NbtcContract,
    dwallet_coordinator: &DWalletCoordinator,
    redeem_id: u64,
    input_idx: u32,
    sign_id: ID,
) {
    let r = &mut contract.redeem_requests[redeem_id];
    assert!(r.has_signature(input_idx), EInvalidSignId);

    // TODO: ensure we get right spend key, because this spend key can also inactive_spend_key
    // let sign_hash = r.sig_hash(input_idx);
    // let dwallet_id = r.utxo_at(input_idx).dwallet_id;
    // let signature = get_signature(dwallet_coordinator, dwallet_id, sign_id);
    // let pk = r.public_key()
    // let is_valid = sui::ecdsa_k1::secp256k1_verify(
    //     &signature,
    //     &pk,
    //     &sign_hash,
    //     SHA256 as u8,
    // );

    // let is_valid = r.validate_signature(dwallet_coordinator, redeem_id, input_idx, sign_id)
    // assert!(is_valid, ESignatureInValid);
    // r.add_signature(input_idx, signature);
    r.validate_signature(dwallet_coordinator, redeem_id, input_idx, sign_id);
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
    dwallet_cap: DWalletCap,
    spend_key: vector<u8>,
    public_key: vector<u8>,
) {
    // TODO: Verify spend_key derive from dwallet public key
    contract.dwallet_pks.add(object::id(&dwallet_cap), public_key);
    contract.dwallet_caps.add(spend_key, dwallet_cap);
}

/// Set btc endpoint for deposit on nBTC, and set reserve of this endpoint is zero.
/// In the case, we use this key before we will enable deposit endpoint again.
public fun add_spend_key(_: &AdminCap, contract: &mut NbtcContract, key: vector<u8>) {
    // TODO: add_spend_key and add_dwallet_cap is the same function.
    // Refactor to one
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

public(package) fun add_utxo_to_contract(
    contract: &mut NbtcContract,
    tx_id: vector<u8>,
    vout: u32,
    value: u64,
) {
    let utxo_idx = contract.next_utxo;
    let utxo = nbtc_utxo::new_utxo(tx_id, vout, value);
    contract.utxos.add(utxo_idx, utxo);
    contract.next_utxo = contract.next_utxo + 1;
}

/// Remove a UTXO from the contract
public fun remove_utxo(_: &AdminCap, contract: &mut NbtcContract, utxo_idx: u64) {
    contract.utxos.remove(utxo_idx);
}

//
// View functions
//

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

/// Return public key of spend_key
public(package) fun public_key_of(contract: &NbtcContract, spend_key: vector<u8>): vector<u8> {
    let dwallet_cap = &contract.dwallet_caps[spend_key];
    contract.dwallet_pks[object::id(dwallet_cap)]
}

public fun redeem_request(contract: &NbtcContract, request_id: u64): &RedeemRequest {
    &contract.redeem_requests[request_id]
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
        dwallet_pks: table::new(ctx),
        redeem_requests: table::new(ctx),
        locked: table::new(ctx),
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
public fun add_utxo_for_test(ctr: &mut NbtcContract, idx: u64, utxo: Utxo) {
    ctr.utxos.add(idx, utxo);
}

#[test_only]
public fun dwallet_caps(contract: &NbtcContract, spend_key: vector<u8>): &DWalletCap {
    &contract.dwallet_caps[spend_key]
}

#[test_only]
public fun dwallet_pks_of(contract: &NbtcContract, id: ID): vector<u8> {
    contract.dwallet_pks[id]
}

#[test_only]
public fun create_redeem_request_for_testing(
    contract: &mut NbtcContract,
    request_id: u64,
    redeemer: address,
    recipient_script: vector<u8>,
    amount: u64,
    fee: u64,
    utxos: vector<Utxo>,
    signatures: vector<vector<u8>>,
    ctx: &mut TxContext,
) {
    let r = sign_request::new(
        contract.bitcoin_spend_key,
        redeemer,
        recipient_script,
        amount,
        fee,
        ctx,
    );
    contract
        .redeem_requests
        .add(
            request_id,
            r,
        )
}

#[test_only]
public fun admin_cap_for_testing(ctx: &mut TxContext): AdminCap {
    AdminCap {
        id: object::new(ctx),
    }
}

#[test_only]
public fun redeem_request_mut(contract: &mut NbtcContract, request_id: u64): &mut RedeemRequest {
    &mut contract.redeem_requests[request_id]
}
