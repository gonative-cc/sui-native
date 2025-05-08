// SPDX-License-Identifier: MPL-2.0

module nbtc_swap::nbtc_swap;

use nbtc::nbtc::NBTC;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::sui::SUI;

const EvaultPaused: u64 = 1;
const EInsufficientLiquidity: u64 = 2;
const EInvalidPrice: u64 = 3;
const EInsufficientSuiPayment: u64 = 4;

// SUI has 9 decimals: 1 SUI = 10^9 MIST
// NBTC has 8 decimals: 1 NBTC = 10^8 satoshi
// The conversion factor for price = 10^9 / 10^8 = 10
const PRICE_CONVERSION_FACTOR: u64 = 10;

public struct AdminCap has key, store {
    id: UID,
}

public struct Vault has key, store {
    id: UID,
    nbtc_balance: Balance<NBTC>,
    sui_balance: Balance<SUI>,
    price_per_nbtc_satoshi_in_mist: u64,
    admin: address,
    is_paused: bool,
}

fun init(ctx: &mut TxContext) {
    let initial_price = 25000; //25k SUI per NBTC
    let sender = tx_context::sender(ctx);

    transfer::transfer(
        AdminCap {
            id: object::new(ctx),
        },
        sender,
    );

    let vault = Vault {
        id: object::new(ctx),
        nbtc_balance: coin::zero<NBTC>(ctx).into_balance(),
        sui_balance: coin::zero<SUI>(ctx).into_balance(),
        price_per_nbtc_satoshi_in_mist: calculate_price(initial_price),
        admin: sender,
        is_paused: false,
    };

    transfer::share_object(vault);
}

fun calculate_price(price: u64): u64 {
    price  * PRICE_CONVERSION_FACTOR
}

public entry fun swap_sui_for_nbtc(vault: &mut Vault, coin: Coin<SUI>, ctx: &mut TxContext) {
    assert!(!vault.is_paused, EvaultPaused);

    let sender = tx_context::sender(ctx);
    let sui_paid = coin.into_balance();

    let nbtc_to_receive = sui_paid.value() / vault.price_per_nbtc_satoshi_in_mist;
    assert!(nbtc_to_receive > 0, EInsufficientSuiPayment);

    vault.sui_balance.join(sui_paid);
    let vault_nbtc_balance = vault.nbtc_balance.value();

    assert!(vault_nbtc_balance >= nbtc_to_receive, EInsufficientLiquidity);

    let nbtc_to_send = coin::take(&mut vault.nbtc_balance, nbtc_to_receive, ctx);

    transfer::public_transfer(nbtc_to_send, sender);
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

public entry fun withdraw(_cap: &AdminCap, vault: &mut Vault, ctx: &mut TxContext) {
    let nbtc_amount = vault.nbtc_balance.value();
    let sui_amount = vault.sui_balance.value();
    let nbtc_to_withdraw = coin::take(&mut vault.nbtc_balance, nbtc_amount, ctx);
    let sui_to_withdraw = coin::take(&mut vault.sui_balance, sui_amount, ctx);
    transfer::public_transfer(nbtc_to_withdraw, vault.admin);
    transfer::public_transfer(sui_to_withdraw, vault.admin)
}

// Input the new price in standard units (e.g., 25000 for 25k SUI per NBTC)
public entry fun set_price(
    _cap: &AdminCap,
    vault: &mut Vault,
    new_price: u64,
    _ctx: &mut TxContext,
) {
    assert!(new_price > 0, EInvalidPrice);
    vault.price_per_nbtc_satoshi_in_mist = calculate_price(new_price);
}

public entry fun set_paused(_cap: &AdminCap, vault: &mut Vault, pause: bool, _ctx: &mut TxContext) {
    vault.is_paused = pause;
}

public fun price(vault: &Vault): u64 {
    vault.price_per_nbtc_satoshi_in_mist
}

public fun nbtc_liquidity(vault: &Vault): u64 {
    balance::value(&vault.nbtc_balance)
}

public fun is_paused(vault: &Vault): bool {
    vault.is_paused
}
