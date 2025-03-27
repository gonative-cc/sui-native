/// Module: nbtc
module nbtc::nbtc;

use sui::coin::{Self, Coin, TreasuryCap};
use sui::url;
use bitcoin_spv::light_client::LightClient;
use bitcoin_spv::transaction::make_transaction;
use bitcoin_spv::light_client::prove_payment;
use sui::table::{Self, Table};
use sui::address;

/// CONSTANTS
/// --COIN METADATA--
const DECIMALS: u8 = 8;
const SYMBOL: vector<u8> = b"NBTC";
const NAME: vector<u8> = b"Native BTC";
const DESCRIPTION: vector<u8> = b"Natvie synthetic BTC powered by IKA.";
const ICON_URL: vector<u8> = b"icon.url";
/// --CONFIG--
const TRUSTED_LIGHT_CLIENT_ID: address =@0xCA;
const FALLBACK_ADDRESS: address = @0xCF;
const BTC_TREASURY: vector<u8> = b"btc_address";

/// OTW
public struct NBTC has drop {}

/// ERRROS
const ETxAlreadyUsed: u64 = 0;
const EMintAmountIsZero: u64 = 1;
const EUntrustedLightClient: u64 = 2;

/// STRUCTS
public struct WrappedTreasuryCap has key, store {
    id: UID,
    cap: TreasuryCap<NBTC>,
    tx_ids: Table<vector<u8>, bool>, //TODO: consider using dynamic fields if we dont need anything
    trusted_lc_id: ID,
    fallback_address: address,
    btc_treasury: vector<u8>,
}

fun init(witness: NBTC, ctx: &mut TxContext) {
    let (treasury_cap, metadata) = coin::create_currency<NBTC>(
        witness,
        DECIMALS,
        SYMBOL,
        NAME,
        DESCRIPTION,
        option::some(url::new_unsafe_from_bytes(ICON_URL)),
        ctx
    );

    transfer::public_freeze_object(metadata);
    let treasury =
     WrappedTreasuryCap {
         id: object::new(ctx),
         cap: treasury_cap,
         tx_ids: table::new<vector<u8>, bool>(ctx),
         trusted_lc_id: TRUSTED_LIGHT_CLIENT_ID.to_id(),
         fallback_address: FALLBACK_ADDRESS,
         btc_treasury: BTC_TREASURY,
         };
    transfer::public_share_object(treasury);

}

/// PUBLIC ENTRY FUNCTIONS
public fun mint(
    treasury: &mut WrappedTreasuryCap,
    light_client: &LightClient,
    version: vector<u8>,
    input_count: u256,
    inputs: vector<u8>,
    output_count: u256,
    outputs: vector<u8>,
    lock_time: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    ctx: &mut TxContext,
) {
    let provided_lc_id = object::id(light_client);
        assert!(
            provided_lc_id == treasury.trusted_lc_id,
            EUntrustedLightClient
        );

    let tx = make_transaction(version, input_count, inputs, output_count, outputs, lock_time);
    let (amount_satoshi, op_return, tx_id) = prove_payment(light_client, height, proof, tx_index, &tx, treasury.btc_treasury);

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

    coin::mint_and_transfer(&mut treasury.cap, amount_satoshi as u64, recipient_address, ctx);
    //TODO: consider adding an event
}

public entry fun burn(
    treasury: &mut WrappedTreasuryCap,
    coin_to_burn: Coin<NBTC>,
    _ctx: &mut TxContext,
) {
    //TODO: implement logic to guard burning
    coin::burn(&mut treasury.cap, coin_to_burn);
}

/// VIEW FUNCTIONS
public fun total_supply(treasury: &WrappedTreasuryCap): u64 {
    coin::total_supply(&treasury.cap)
}

public fun get_trusted_light_client_id(treasury: &WrappedTreasuryCap): ID {
    treasury.trusted_lc_id
}

public fun get_fallback_address(treasury: &WrappedTreasuryCap): address {
    treasury.fallback_address
}
