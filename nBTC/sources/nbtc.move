/// Module: nbtc
module nbtc::nbtc;

use sui::coin::{Self, Coin, TreasuryCap};
use sui::url;

/// CONSTANTS
const DECIMALS: u8 = 9;
const SYMBOL: vector<u8> = b"NBTC";
const NAME: vector<u8> = b"Native BTC";
const DESCRIPTION: vector<u8> = b"Natvie synthetic BTC powered by IKA.";
const ICON_URL: vector<u8> = b"icon.url";

/// OTW
public struct NBTC has drop {}

/// STRUCTS
public struct WrappedTreasuryCap has key, store {
    id: UID,
    treasury_cap: TreasuryCap<NBTC>,
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
    // TODO: add lc and fallback addr

    transfer::public_freeze_object(metadata);
    let wrapped_treasury_cap = WrappedTreasuryCap { id: object::new(ctx), treasury_cap };
    transfer::public_share_object(wrapped_treasury_cap)
}

/// MINT
public fun mint(
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
    treasury_cap: &mut WrappedTreasuryCap,
) {
    //TODO: call verfiy module and then call mint_int
}

public fun mint_int( 
    amount: u64,
    recipient: address,
    ctx: &mut TxContext,
    treasury: &mut WrappedTreasuryCap,
) {
    coin::mint_and_transfer(treasury.treasury_cap, amount, recipient, ctx)
}