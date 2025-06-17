// SPDX-License-Identifier: MPL-2.0

module nbtc_swap::nbtc_swap;

use nbtc::nbtc::NBTC;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::event::emit;
use sui::sui::SUI;

const EVaultPaused: u64 = 1;
const EInsufficientLiquidity: u64 = 2;
const EInvalidPrice: u64 = 3;
const EInsufficientSuiPayment: u64 = 4;

// SUI has 9 decimals: 1 SUI = 10^9 MIST
// nBTC has 8 decimals: 1 nBTC = 10^8 satoshi
// The conversion factor for price = 10^9 / 10^8 = 10
const PRICE_CONVERSION_FACTOR: u64 = 10;

/// Event emitted when nBTC is purchased. Contains address of the buyer and the amount of nBTC bought.
public struct Buy has copy, drop {
    buyer: address,
    amount: u64,
}

/// Event emitted when nBTC is sold. Contains address of the seller and the amount of nBTC sold.
public struct Sell has copy, drop {
    seller: address,
    amount: u64,
}

public struct AdminCap has key, store {
    id: UID,
}

public struct Vault has key, store {
    id: UID,
    nbtc_balance: Balance<NBTC>,
    sui_balance: Balance<SUI>,
    /// 1 satoshi BTC price in MIST
    satoshi_price: u64,
    admin: address,
    is_paused: bool,
}

fun init(ctx: &mut TxContext) {
    let initial_price = 25000; //25k SUI per NBTC
    let sender = ctx.sender();

    let vault = Vault {
        id: object::new(ctx),
        nbtc_balance: coin::zero<NBTC>(ctx).into_balance(),
        sui_balance: coin::zero<SUI>(ctx).into_balance(),
        satoshi_price: calculate_price(initial_price),
        admin: sender,
        is_paused: false,
    };

    transfer::transfer(
        AdminCap {
            id: object::new(ctx),
        },
        sender,
    );
    transfer::share_object(vault);
}

fun calculate_price(price: u64): u64 {
    price  * PRICE_CONVERSION_FACTOR
}

public fun buy_nbtc(vault: &mut Vault, coin: Coin<SUI>, ctx: &mut TxContext): Coin<NBTC> {
    assert!(!vault.is_paused, EVaultPaused);

    let sui_paid = coin.into_balance();
    let nbtc_to_receive = sui_paid.value() / vault.satoshi_price;
    assert!(nbtc_to_receive > 0, EInsufficientSuiPayment);
    let vault_nbtc_balance = vault.nbtc_balance.value();
    assert!(vault_nbtc_balance >= nbtc_to_receive, EInsufficientLiquidity);

    vault.sui_balance.join(sui_paid);
    let nbtc_to_send = coin::take(&mut vault.nbtc_balance, nbtc_to_receive, ctx);

    emit(Buy { buyer: ctx.sender(), amount: nbtc_to_receive });

    nbtc_to_send
}

public fun sell_nbtc(vault: &mut Vault, coin: Coin<NBTC>, ctx: &mut TxContext): Coin<SUI> {
    assert!(!vault.is_paused, EVaultPaused);

    let nbtc_paid = coin.into_balance();
    let nbtc_amount = nbtc_paid.value();
    let sui_to_recive = nbtc_amount * vault.satoshi_price / 2; // we enable selling for half of price of the buy
    assert!(sui_to_recive > 0, EInsufficientSuiPayment);
    let vault_sui_balance = vault.sui_balance.value();
    assert!(vault_sui_balance >= sui_to_recive, EInsufficientLiquidity);

    vault.nbtc_balance.join(nbtc_paid);
    let sui_to_send = coin::take(&mut vault.sui_balance, sui_to_recive, ctx);

    emit(Sell { seller: ctx.sender(), amount: nbtc_amount });

    sui_to_send
}

public entry fun add_nbtc_liquidity(
    _cap: &AdminCap,
    vault: &mut Vault,
    nbtc_coin: Coin<NBTC>,
    _ctx: &mut TxContext,
) {
    let nbtc_added = nbtc_coin.into_balance();
    vault.nbtc_balance.join(nbtc_added);
}

/// sends all nBTC and Sui to admin
public entry fun withdraw(_cap: &AdminCap, vault: &mut Vault, ctx: &mut TxContext) {
    let nbtc_amount = vault.nbtc_balance.value();
    let sui_amount = vault.sui_balance.value();
    let nbtc_to_withdraw = coin::take(&mut vault.nbtc_balance, nbtc_amount, ctx);
    let sui_to_withdraw = coin::take(&mut vault.sui_balance, sui_amount, ctx);
    transfer::public_transfer(nbtc_to_withdraw, vault.admin);
    transfer::public_transfer(sui_to_withdraw, vault.admin)
}

/// Input the new price in standard units (e.g., 25000 for 25k SUI per NBTC)
public entry fun set_price(
    _cap: &AdminCap,
    vault: &mut Vault,
    new_price: u64,
    _ctx: &mut TxContext,
) {
    assert!(new_price > 0, EInvalidPrice);
    vault.satoshi_price = calculate_price(new_price);
}

public entry fun set_paused(_cap: &AdminCap, vault: &mut Vault, pause: bool, _ctx: &mut TxContext) {
    vault.is_paused = pause;
}

/// returns price of 1 nano nBTC in MIST
public fun price(vault: &Vault): u64 {
    vault.satoshi_price
}

public fun nbtc_liquidity(vault: &Vault): u64 {
    balance::value(&vault.nbtc_balance)
}

public fun is_paused(vault: &Vault): bool {
    vault.is_paused
}
