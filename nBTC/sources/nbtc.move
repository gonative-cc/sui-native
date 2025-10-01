// SPDX-License-Identifier: MPL-2.0

module nbtc::nbtc;

use bitcoin_parser::reader;
use bitcoin_parser::tx;
use bitcoin_spv::light_client::LightClient;
use nbtc::verify_payment::verify_payment;
use sui::address;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin, TreasuryCap};
use sui::event;
use sui::table::{Self, Table};
use sui::url;

//
// Constant
//

/// Package version
const VERSION: u32 = 1;

/// Coin Metadata
const DECIMALS: u8 = 8;
const SYMBOL: vector<u8> = b"nBTC";
const NAME: vector<u8> = b"nBTC";
const DESCRIPTION: vector<u8> = b"Native synthetic BTC";
const ICON_URL: vector<u8> =
    b"https://raw.githubusercontent.com/gonative-cc/sui-native/master/assets/nbtc.svg";

/// ops_arg consts
const MINT_OP_APPLY_FEE: u32 = 1;

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
    bitcoin_spend_key: vector<u8>,
    /// BTC balances for the current bitcoin_spend_key.
    active_balance: u64,
    /// If user, by mistake, will use inactive spend key, then we should protect from a BTC dedlock
    /// in that account. In such case we don't mint nBTC, but we allow the user to transfer it back.
    /// NOTE: for efficiencty, this vector must be sorted.
    inactive_spend_keys: vector<vector<u8>>,
    /// Maps user address to his BTC deposit (in case he deposited to an inactive key from the list
    /// above). TODO: must be per (spend_key, address)
    inactive_user_balances: Table<address, u64>,
    /// total balance per inactive key, indexed accordingly to inactive_spend_keys.
    inactive_balances: vector<u64>,
    /// as in Balance<nBTC>
    mint_fee: u64,
    fees_collected: Balance<NBTC>,
}

/// MintEvent is emitted when nBTC is successfully minted.
public struct MintEvent has copy, drop {
    recipient: address,
    amount: u64, // in satoshi
    fee: u64,
    /// Bitcoin transaction ID
    btc_tx_id: vector<u8>,
    btc_block_height: u64,
    /// index of the tx within the block.
    btc_tx_index: u64,
}

public struct InactiveDepositEvent has copy, drop {
    bitcoin_spend_key: vector<u8>,
    recipient: address,
    amount: u64, // in satoshi
    /// Bitcoin transaction ID
    btc_tx_id: vector<u8>,
    btc_block_height: u64,
    /// index of the tx within the block.
    btc_tx_index: u64,
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
    assert!(bitcoin_spend_key.length() >= 23);
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
        fees_collected: balance::zero(),
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
// Public functions
//

/// Mints nBTC tokens after verifying a Bitcoin transaction proof.
/// * `deposit_spend_key`: bitcoin spend pub key the user used for the UTXO nBTC deposit.
/// * `tx_bytes`: raw, hex-encoded tx bytes.
/// * `proof`: merkle proof for the tx.
/// * `height`: block height, where the tx was included.
/// * `tx_index`: index of the tx within the block.
/// * `payload`: additional argument that is related to the op_return instruction handling.
/// * `ops_arg`: operation argument controlling fee application.
///   - Pass `1` to apply minting fees.
///   - Pass `0` to skip minting fees (for special cases or admin operations).
/// Emits `MintEvent` if successful.
public fun mint(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    deposit_spend_key: vector<u8>,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    // TODO: The `payload` parameter is reserved for future use related to advanced op_return instruction handling.
    //       Implementation pending. Do not remove; will be used to support additional minting logic.
    _payload: vector<u8>,
    ops_arg: u32,
    ctx: &mut TxContext,
) {
    assert!(contract.version == VERSION, EVersionMismatch);
    assert!(ops_arg == 0 || ops_arg == MINT_OP_APPLY_FEE, EInvalidOpsArg);
    let provided_lc_id = object::id(light_client);
    assert!(provided_lc_id == contract.get_light_client_id(), EUntrustedLightClient);
    let mut inactive_key_idx = contract.inactive_key_idx(deposit_spend_key);
    assert!(
        deposit_spend_key == contract.bitcoin_spend_key || inactive_key_idx.is_some(),
        EInvalidDepositKey,
    );

    let mut r = reader::new(tx_bytes);
    let tx = tx::deserialize(&mut r);

    let tx_id = tx.tx_id();

    // Double spend prevent
    assert!(!contract.tx_ids.contains(tx_id), ETxAlreadyUsed);
    contract.tx_ids.add(tx_id, true);
    // NOTE: We assume only one active key. We should handle mutiple nbtc active key in the
    // future.
    let (mut amount, mut op_return) = verify_payment(
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

    if (inactive_key_idx.is_some()) {
        let key_idx = inactive_key_idx.extract();
        let bal = &mut contract.inactive_balances[key_idx];
        *bal = *bal + amount;
        if (contract.inactive_user_balances.contains(recipient)) {
            let user_bal = &mut contract.inactive_user_balances[recipient];
            *user_bal = *user_bal + amount;
        } else {
            contract.inactive_user_balances.add(recipient, amount);
        };
        event::emit(InactiveDepositEvent {
            bitcoin_spend_key: deposit_spend_key,
            recipient,
            amount,
            btc_tx_id: tx_id,
            btc_block_height: height,
            btc_tx_index: tx_index,
        });

        // TODO: add event for inactive deposit

        return
    };

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
        btc_tx_id: tx_id,
        btc_block_height: height,
        btc_tx_index: tx_index,
    });
}

/// Like mint, but records deposit to an inacitve address instead of minting.
public fun record_inactive_deposit(
    contract: &mut NbtcContract,
    light_client: &LightClient,
    deposit_spend_key: vector<u8>,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    // TODO: The `payload` parameter is reserved for future use related to advanced op_return instruction handling.
    //       Implementation pending. Do not remove; will be used to support additional minting logic.
    _payload: vector<u8>,
    ops_arg: u32,
    ctx: &mut TxContext,
) {}

/// redeem returns total amount of redeemed balance
public fun redeem(
    contract: &mut NbtcContract,
    coins: vector<Coin<NBTC>>,
    _bitcoin_recipient: vector<u8>,
    _ctx: &mut TxContext,
): u64 {
    assert!(contract.version == VERSION, EVersionMismatch);
    // TODO: implement logic to guard burning
    // TODO: we can detele the btc public key when reserves of this key is zero
    coins.fold!(0, |total, c| total + coin::burn(&mut contract.cap, c))
}

/// Allows user to redeem back deposited BTC to an inactive nBTC deposit spend key.
public fun redeem_from_inactive(
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
    let amount = contract.inactive_user_balances.remove(sender);
    let total_bal = &mut contract.inactive_balances[key_idx];
    *total_bal = *total_bal - amount;

    event::emit(RedeemInactiveDepositEvent {
        bitcoin_spend_key: deposit_spend_key,
        recipient: bitcoin_recipient,
        amount,
    });

    // TODO: implement logic to guard burning
    // TODO: we can detele the btc public key when reserves of this key is zero

    amount
}

/// update_version updates the contract.version to the latest, making the usage of the older versions not possible
public fun update_version(contract: &mut NbtcContract) {
    assert!(VERSION > contract.version, EAlreadyUpdated);
    contract.version = VERSION;
}

/// returns idx of key in in inactive_spend_keys or None if the key is not there
public fun inactive_key_idx(contract: &mut NbtcContract, key: vector<u8>): Option<u64> {
    // TODO: implement binary search
    option::none()
}

//
// Admin functions
//

public fun withdraw_fees(_: &OpCap, contract: &mut NbtcContract, ctx: &mut TxContext): Coin<NBTC> {
    coin::from_balance(contract.fees_collected.withdraw_all(), ctx)
}

public fun change_fees(_: &AdminCap, contract: &mut NbtcContract, mint_fee: u64) {
    contract.mint_fee = mint_fee;
}

/// Set btc endpoint for deposit on nBTC, and set reserve of this endpoint is zero.
/// In the case, we use this key before we will enable deposit endpoint again.
public fun add_spend_key(_: &AdminCap, contract: &mut NbtcContract, key: vector<u8>) {
    let key_idx = contract.inactive_key_idx(key);
    assert!(contract.bitcoin_spend_key != key && key_idx.is_none(), EDuplicatedKey);

    let insert_idx = insert_ordered(&contract.inactive_spend_keys, contract.bitcoin_spend_key);
    contract.inactive_spend_keys.insert(contract.bitcoin_spend_key, insert_idx);
    contract.bitcoin_spend_key = key;
    contract.inactive_balances.insert(insert_idx, 0);

    // TODO:
    // - make BTC transaction (using Ika) to move fomr the old key to the new key
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

public fun bitcoin_spend_key(contract: &NbtcContract): vector<u8> {
    contract.bitcoin_spend_key
}

//
// Helper functions
//

/// inserts the new key in vector, keeping it ordered. Return insert index.
public fun insert_ordered(v: &vector<vector<u8>>, key: vector<u8>): u64 {
    // TODO: implement binary search
    0
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
        mint_fee: 10,
    };
    contract
}

#[test_only]
public fun get_fees_collected(contract: &NbtcContract): u64 {
    contract.fees_collected.value()
}
