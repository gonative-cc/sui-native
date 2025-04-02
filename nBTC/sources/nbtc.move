/// Module: nbtc
module nbtc::nbtc;

use bitcoin_spv::light_client::{LightClient, prove_payment};
use bitcoin_spv::transaction::make_transaction;

use sui::event;
use sui::address;
use sui::coin::{Self, Coin, TreasuryCap};
use sui::table::{Self, Table};
use sui::url;

//
// Constans
//

/// Coin Metadata
const DECIMALS: u8 = 8;
const SYMBOL: vector<u8> = b"NBTC";
const NAME: vector<u8> = b"Native BTC";
const DESCRIPTION: vector<u8> = b"Natvie synthetic BTC powered by IKA.";
const ICON_URL: vector<u8> = b"icon.url";

// Configuration
/// The Object ID of the trusted Bitcoin SPV Light Client.
const TRUSTED_LIGHT_CLIENT_ID: address = @0xCA;
/// The fallback Sui address to receive nBTC if OP_RETURN data is invalid or missing.
const FALLBACK_ADDRESS: address = @0xCF;
/// The Bitcoin address where users must send BTC to mint nBTC.
const BTC_TREASURY: vector<u8> = b"btc_address";

/// One Time Witness
public struct NBTC has drop {}

// Errors
#[error]
const ETxAlreadyUsed: vector<u8> = b"The provided Bitcoin transaction ID has already been used for minting.";
#[error]
const EMintAmountIsZero: vector<u8> = b"The amount from the Bitcoin transaction to be minted is zero.";
#[error]
const EUntrustedLightClient: vector<u8> = b"The provided Light Client object ID does not match the trusted one.";

//
// Structs
//

/// WrappedTreasuryCap holds the TreasuryCap as well as configuration and state.
/// It should be a shared object to enable anyone to interact with the contract.
public struct WrappedTreasuryCap has key, store {
    id: UID,
    cap: TreasuryCap<NBTC>,
    tx_ids: Table<vector<u8>, bool>, //TODO: consider using dynamic fields if we dont need anything
    trusted_lc_id: ID,
    fallback_address: address,
    btc_treasury: vector<u8>,
}

/// MintEvent is emitted when nBTC is successfully minted.
public struct MintEvent has copy, drop, store {
    minter: address,
    recipient: address,
    amount: u64, // in satoshi
    btc_tx_id: vector<u8>,
    btc_block_height: u64,
    btc_tx_index: u64,
}

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

    transfer::public_freeze_object(metadata);
    let treasury = WrappedTreasuryCap {
        id: object::new(ctx),
        cap: treasury_cap,
        tx_ids: table::new<vector<u8>, bool>(ctx),
        trusted_lc_id: TRUSTED_LIGHT_CLIENT_ID.to_id(),
        fallback_address: FALLBACK_ADDRESS,
        btc_treasury: BTC_TREASURY,
    };
    transfer::public_share_object(treasury);
}

//
// Public functions
//

/// Mints nBTC tokens after verifying a Bitcoin transaction proof.
/// * `input_count`: number of input objects
/// * `inputs`: all tx inputs encoded as a single list of bytes.
/// * `output_count`: number of output objects
/// * `outputs`: all tx outputs encoded as a single list of bytes.
/// Emits `MintEvent` if succesfull.
public fun mint(
    treasury: &mut WrappedTreasuryCap,
    light_client: &LightClient,
    version: vector<u8>,
    input_count: u32,
    inputs: vector<u8>,
    output_count: u32,
    outputs: vector<u8>,
    lock_time: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    ctx: &mut TxContext,
) {
    let provided_lc_id = object::id(light_client);
    assert!(provided_lc_id == treasury.trusted_lc_id, EUntrustedLightClient);

    let tx = make_transaction(
        version,
        input_count as u256,
        inputs,
        output_count as u256,
        outputs,
        lock_time,
    );
    let (amount_satoshi, op_return, tx_id) = prove_payment(
        light_client,
        height,
        proof,
        tx_index,
        &tx,
        treasury.btc_treasury,
    );

    assert!(!treasury.tx_ids.contains(tx_id), ETxAlreadyUsed);
    assert!(amount_satoshi > 0, EMintAmountIsZero);
    let recipient_address: address;
    if (op_return.length() == 32) {
        //TODO: we need more advanced parsing. For PoC we just check the length, else use fallback
        recipient_address = address::from_bytes(op_return);
    } else {
        recipient_address = treasury.fallback_address;
    };
    treasury.tx_ids.add(tx_id, true);

    // TODO remove u64
    coin::mint_and_transfer(&mut treasury.cap, amount_satoshi as u64, recipient_address, ctx);

    event::emit(MintEvent {
        minter: tx_context::sender(ctx),
        recipient: recipient_address,
        amount: amount_satoshi as u64,
        btc_tx_id: tx_id,
        btc_block_height: height,
        btc_tx_index: tx_index,
    });
}

public fun burn(treasury: &mut WrappedTreasuryCap, coin_to_burn: Coin<NBTC>, _ctx: &mut TxContext) {
    //TODO: implement logic to guard burning
    coin::burn(&mut treasury.cap, coin_to_burn);
}

//
// View functions
//

public fun total_supply(treasury: &WrappedTreasuryCap): u64 {
    coin::total_supply(&treasury.cap)
}

public fun get_trusted_light_client_id(treasury: &WrappedTreasuryCap): ID {
    treasury.trusted_lc_id
}

public fun get_fallback_address(treasury: &WrappedTreasuryCap): address {
    treasury.fallback_address
}
