// SPDX-License-Identifier: MPL-2.0

module nbtc::nbtc;

use bitcoin_parser::reader;
use bitcoin_parser::tx;
use bitcoin_spv::light_client::LightClient;
use nbtc::verify_payment::verify_payment;
use sui::address;
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
    nbtc_bitcoin_pkh: vector<u8>,
}

/// MintEvent is emitted when nBTC is successfully minted.
public struct MintEvent has copy, drop {
    minter: address,
    recipient: address,
    amount: u64, // in satoshi
    /// Bitcoin transaction ID
    btc_tx_id: vector<u8>,
    btc_block_height: u64,
    /// index of the tx within the block.
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

    // we removed post deployment setup function and didn't want to implement PTB style
    // initialization, so we require setting the address before publishing the package.
    let nbtc_bitcoin_pkh = b""; // TODO: valid bitcoin address
    assert!(nbtc_bitcoin_pkh.length() >= 23);
    transfer::public_freeze_object(metadata);
    let treasury = NbtcContract {
        id: object::new(ctx),
        version: VERSION,
        cap: treasury_cap,
        tx_ids: table::new<vector<u8>, bool>(ctx),
        bitcoin_lc: @bitcoin_lc.to_id(),
        fallback_addr: @fallback_addr,
        nbtc_bitcoin_pkh,
    };
    transfer::public_share_object(treasury);
}

//
// Public functions
//

/// Mints nBTC tokens after verifying a Bitcoin transaction proof.
/// * `tx_bytes`: raw, hex-encoded tx bytes.
/// * `proof`: merkele proof for the tx.
/// * `height`: block height, where the tx was included.
/// * `tx_index`: index of the tx within the block.
/// Emits `MintEvent` if succesfull.
public fun mint(
    treasury: &mut NbtcContract,
    light_client: &LightClient,
    tx_bytes: vector<u8>,
    proof: vector<vector<u8>>,
    height: u64,
    tx_index: u64,
    ctx: &mut TxContext,
) {
    assert!(treasury.version == VERSION, EVersionMismatch);
    let provided_lc_id = object::id(light_client);
    assert!(provided_lc_id == treasury.get_light_client_id(), EUntrustedLightClient);

    let mut r = reader::new(tx_bytes);
    let tx = tx::deserialize(&mut r);

    let tx_id = tx.tx_id();
    let (amount_satoshi, mut op_return) = verify_payment(
        light_client,
        height,
        proof,
        tx_index,
        &tx,
        treasury.nbtc_bitcoin_pkh,
    );

    assert!(!treasury.tx_ids.contains(tx_id), ETxAlreadyUsed);
    assert!(amount_satoshi > 0, EMintAmountIsZero);

    let mut recipient_address: address = treasury.get_fallback_addr();

    if (op_return.is_some()) {
        let msg = op_return.extract();
        let mut msg_reader = reader::new(msg);
        let flag = msg_reader.read_byte();
        if (flag == 0x00) {
            if (msg_reader.readable(32)) {
                recipient_address = address::from_bytes(msg_reader.read(32));
            };

            // stream not end, format is invalid, move data to fallback
            if (!msg_reader.end_stream()) {
                recipient_address = treasury.get_fallback_addr();
            }
        }
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
    treasury: &mut NbtcContract,
    coins: vector<Coin<NBTC>>,
    _ctx: &mut TxContext,
): u64 {
    assert!(treasury.version == VERSION, EVersionMismatch);
    // TODO: implement logic to guard burning
    coins.fold!(0, |total, c| total + coin::burn(&mut treasury.cap, c))
}

/// update_version updates the treasury.version to the latest, making the usage of the older versions not possible
public fun update_version(treasury: &mut NbtcContract) {
    assert!(VERSION > treasury.version, EAlreadyUpdated);
    treasury.version = VERSION;
}

//
// View functions
//

public fun total_supply(treasury: &NbtcContract): u64 {
    coin::total_supply(&treasury.cap)
}

public fun get_light_client_id(treasury: &NbtcContract): ID {
    treasury.bitcoin_lc
}

public fun get_fallback_addr(treasury: &NbtcContract): address {
    treasury.fallback_addr
}

//
// Testing
//

#[test_only]
public(package) fun init_for_testing(
    ctx: &mut TxContext,
    bitcoin_lc: address,
    fallback_addr: address,
    nbtc_bitcoin_pkh: vector<u8>,
): NbtcContract {
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
    let treasury = NbtcContract {
        id: object::new(ctx),
        version: VERSION,
        cap: treasury_cap,
        tx_ids: table::new<vector<u8>, bool>(ctx),
        bitcoin_lc,
        fallback_addr,
        nbtc_bitcoin_pkh,
    };
    treasury
}
