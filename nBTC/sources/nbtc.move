// SPDX-License-Identifier: MPL-2.0

module nbtc::nbtc;

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
use sui::coin_registry;
use sui::event;
use sui::sui::SUI;
use sui::table::{Self, Table};
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

//
// Errors
//

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

//
// Structs
//

/// Coin type identifier (`Coin<package_object::nbtc::NBTC>`) and One Time Witness.
public struct NBTC has drop {}

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
    /// total deposit balance for each active bitcoin script_pubkey endpoint
    balances: VecMap<vector<u8>, u64>,
    /// as in Balance<nBTC>
    mint_fee: u64,
    fees_collected: Balance<NBTC>,
    // mapping a spend_key to related dWallet cap for issue signature
    dwallet_caps: Table<vector<u8>, DWalletCap>,
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

//
// Functions
//

fun init(witness: NBTC, ctx: &mut TxContext) {
    let (builder, treasury_cap) = coin_registry::new_currency_with_otw(
        witness,
        DECIMALS,
        SYMBOL.to_string(),
        NAME.to_string(),
        DESCRIPTION.to_string(),
        ICON_URL.to_string(),
        ctx,
    );

    let metadata_cap = builder.finalize(ctx);

    // NOTE: we removed post deployment setup function and didn't want to implement PTB style
    // initialization, so we require setting the address before publishing the package.
    let nbtc_bitcoin_spend_key = b""; // TODO: valid bitcoin address
    assert!(nbtc_bitcoin_spend_key.length() >= 22);
    let contract = NbtcContract {
        id: object::new(ctx),
        version: VERSION,
        cap: treasury_cap,
        tx_ids: table::new<vector<u8>, bool>(ctx),
        bitcoin_lc: @bitcoin_lc.to_id(),
        fallback_addr: @fallback_addr,
        bitcoin_spend_key: nbtc_bitcoin_spend_key,
        balances: vec_map::from_keys_values(vector[nbtc_bitcoin_spend_key], vector[0]),
        mint_fee: 10,
        dwallet_caps: table::new(ctx),
        fees_collected: balance::zero(),
    };
    transfer::public_share_object(contract);
    transfer::public_transfer(metadata_cap, ctx.sender());

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
        contract.bitcoin_spend_key,
    );

    assert!(amount > 0, EMintAmountIsZero);

    // update total balance for reserves
    let total_balance = contract.balances.get_mut(&contract.bitcoin_spend_key);
    *total_balance = *total_balance + amount;

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

// TODO: Implement logic for generate the redeem transaction data
// This can be offchain or onchain depends on algorithm we design.
public fun btc_redeem_tx(): vector<u8> {
    b"Go Go Native"
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

/// redeem returns total amount of redeemed balance
public fun redeem(
    contract: &mut NbtcContract,
    coins: vector<Coin<NBTC>>,
    _ctx: &mut TxContext,
): u64 {
    assert!(contract.version == VERSION, EVersionMismatch);
    // TODO: implement logic to guard burning
    // TODO: we can detele the btc public key when reserves of this key is zero
    coins.fold!(0, |total, c| total + coin::burn(&mut contract.cap, c))
}

/// update_version updates the contract.version to the latest, making the usage of the older versions not possible
public fun update_version(contract: &mut NbtcContract) {
    assert!(VERSION > contract.version, EAlreadyUpdated);
    contract.version = VERSION;
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
public fun add_script_pubkey(_: &AdminCap, contract: &mut NbtcContract, script_pubkey: vector<u8>) {
    if (contract.balances.contains(&script_pubkey) == false) {
        contract.balances.insert(script_pubkey, 0);
    };
    contract.bitcoin_spend_key = script_pubkey;
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

public fun balances(contract: &NbtcContract): &VecMap<vector<u8>, u64> {
    &contract.balances
}

public fun bitcoin_spend_key(contract: &NbtcContract): &vector<u8> {
    &contract.bitcoin_spend_key
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
        balances: vec_map::from_keys_values(vector[nbtc_bitcoin_spend_key], vector[0]),
        fees_collected: balance::zero(),
        mint_fee: 10,
        dwallet_caps: table::new(ctx),
    };
    contract
}

#[test_only]
public fun get_fees_collected(contract: &NbtcContract): u64 {
    contract.fees_collected.value()
}
