// SPDX-License-Identifier: MPL-2.0

/// Module: nbtc
module nbtc::nbtc;

use bitcoin_spv::light_client::{LightClient, verify_payment};
use bitcoin_spv::transaction::make_transaction;
use sui::address;
use sui::coin::{Self, Coin, TreasuryCap};
use sui::event;
use sui::table::{Self, Table};
use sui::url;

//
// Constans
//

/// Package version
const VERSION: u8 = 1;

/// Coin Metadata
const DECIMALS: u8 = 8;
const SYMBOL: vector<u8> = b"nBTC";
const NAME: vector<u8> = b"Native BTC";
const DESCRIPTION: vector<u8> = b"Natvie synthetic BTC";
const ICON_URL: vector<u8> =
    b"https://raw.githubusercontent.com/gonative-cc/sui-native/master/assets/nbtc.svg";

// Configuration
/// The Object ID of the Bitcoin SPV Light Client.
const LIGHT_CLIENT_ID: address = @light_client;
/// The fallback Sui address to receive nBTC if OP_RETURN data is invalid or missing.
const FALLBACK_ADDR: address = @fallback;
// TODO: convert to pub key hash
/// The Bitcoin public key hash where users must send BTC to mint nBTC.
/// Corresponds to `tb1qe60n447jylrxa96y6pfgy8pq6x9zafu09ky7cq` address on Bitcoin testnet.
const NBTC_BITCOIN_PKH: vector<u8> = x"ce9f3ad7d227c66e9744d052821c20d18a2ea78f";

/// One Time Witness
public struct NBTC has drop {}

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

//
// Structs
//

/// WrappedTreasuryCap holds the TreasuryCap as well as configuration and state.
/// It should be a shared object to enable anyone to interact with the contract.
public struct WrappedTreasuryCap has key, store {
    id: UID,
    version: u8,
    cap: TreasuryCap<NBTC>,
    tx_ids: Table<vector<u8>, bool>,
    trusted_lc_id: ID,
    fallback_addr: address,
    nbtc_bitcoin_pkh: vector<u8>,
}

/// MintEvent is emitted when nBTC is successfully minted.
public struct MintEvent has copy, drop {
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
        version: VERSION,
        cap: treasury_cap,
        tx_ids: table::new<vector<u8>, bool>(ctx),
        trusted_lc_id: LIGHT_CLIENT_ID.to_id(),
        fallback_addr: FALLBACK_ADDR,
        nbtc_bitcoin_pkh: NBTC_BITCOIN_PKH,
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
    assert!(treasury.version == VERSION, EVersionMismatch);
    let provided_lc_id = object::id(light_client);
    assert!(provided_lc_id == treasury.trusted_lc_id, EUntrustedLightClient);

    let tx = make_transaction(
        version,
        input_count,
        inputs,
        output_count,
        outputs,
        lock_time,
    );
    let (amount_satoshi, op_return, tx_id) = verify_payment(
        light_client,
        height,
        proof,
        tx_index,
        &tx,
        treasury.nbtc_bitcoin_pkh,
    );

    assert!(!treasury.tx_ids.contains(tx_id), ETxAlreadyUsed);
    assert!(amount_satoshi > 0, EMintAmountIsZero);
    let recipient_address: address;
    if (op_return.length() == 32) {
        //TODO: we need more advanced parsing. For PoC we just check the length, else use fallback
        recipient_address = address::from_bytes(op_return);
    } else {
        recipient_address = treasury.fallback_addr;
    };
    treasury.tx_ids.add(tx_id, true);

    coin::mint_and_transfer(&mut treasury.cap, amount_satoshi, recipient_address, ctx);

    event::emit(MintEvent {
        minter: tx_context::sender(ctx),
        recipient: recipient_address,
        amount: amount_satoshi,
        btc_tx_id: tx_id,
        btc_block_height: height,
        btc_tx_index: tx_index,
    });
}

/// redeem returns total amount of redeemed balance
public fun redeem(
    treasury: &mut WrappedTreasuryCap,
    coins: vector<Coin<NBTC>>,
    _ctx: &mut TxContext,
): u64 {
    assert!(treasury.version == VERSION, EVersionMismatch);
    // TODO: implement logic to guard burning
    coins.fold!(0, |total, c| total + coin::burn(&mut treasury.cap, c))
}

/// update_version updates the treasury.version to the latest, making the usage of the older versions not possible
public fun update_version(treasury: &mut WrappedTreasuryCap, _: &mut TxContext) {
    assert!(VERSION > treasury.version, EAlreadyUpdated);
    treasury.version = VERSION;
}

//
// View functions
//

public fun total_supply(treasury: &WrappedTreasuryCap): u64 {
    coin::total_supply(&treasury.cap)
}

public fun get_light_client_id(treasury: &WrappedTreasuryCap): ID {
    treasury.trusted_lc_id
}

public fun get_fallback_addr(treasury: &WrappedTreasuryCap): address {
    treasury.fallback_addr
}

#[test_only]
public(package) fun init_for_testing(
    btc_lc_id: ID,
    nbtc_bitcoin_pkh: vector<u8>,
    ctx: &mut TxContext,
): WrappedTreasuryCap {
    let witness = NBTC {};
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
        version: VERSION,
        cap: treasury_cap,
        tx_ids: table::new<vector<u8>, bool>(ctx),
        trusted_lc_id: btc_lc_id,
        fallback_addr: FALLBACK_ADDR,
        nbtc_bitcoin_pkh,
    };

    treasury
}
