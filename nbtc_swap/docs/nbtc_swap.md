
<a name="(nbtc_swap=0x0)_nbtc_swap"></a>

# Module `(nbtc_swap=0x0)::nbtc_swap`



-  [Struct `AdminCap`](#(nbtc_swap=0x0)_nbtc_swap_AdminCap)
-  [Struct `Vault`](#(nbtc_swap=0x0)_nbtc_swap_Vault)
-  [Constants](#@Constants_0)
-  [Function `init`](#(nbtc_swap=0x0)_nbtc_swap_init)
-  [Function `calculate_price`](#(nbtc_swap=0x0)_nbtc_swap_calculate_price)
-  [Function `swap_sui_for_nbtc`](#(nbtc_swap=0x0)_nbtc_swap_swap_sui_for_nbtc)
-  [Function `add_nbtc_liquidity`](#(nbtc_swap=0x0)_nbtc_swap_add_nbtc_liquidity)
-  [Function `withdraw`](#(nbtc_swap=0x0)_nbtc_swap_withdraw)
-  [Function `set_price`](#(nbtc_swap=0x0)_nbtc_swap_set_price)
-  [Function `set_paused`](#(nbtc_swap=0x0)_nbtc_swap_set_paused)
-  [Function `price`](#(nbtc_swap=0x0)_nbtc_swap_price)
-  [Function `nbtc_liquidity`](#(nbtc_swap=0x0)_nbtc_swap_nbtc_liquidity)
-  [Function `is_paused`](#(nbtc_swap=0x0)_nbtc_swap_is_paused)


<pre><code><b>use</b> (bitcoin_spv=0x0)::block_header;
<b>use</b> (bitcoin_spv=0x0)::btc_math;
<b>use</b> (bitcoin_spv=0x0)::light_block;
<b>use</b> (bitcoin_spv=0x0)::light_client;
<b>use</b> (bitcoin_spv=0x0)::merkle_tree;
<b>use</b> (bitcoin_spv=0x0)::params;
<b>use</b> (bitcoin_spv=0x0)::transaction;
<b>use</b> (bitcoin_spv=0x0)::utils;
<b>use</b> (nbtc=0x0)::nbtc;
<b>use</b> <a href="../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../dependencies/std/hash.md#std_hash">std::hash</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="(nbtc_swap=0x0)_nbtc_swap_AdminCap"></a>

## Struct `AdminCap`



<pre><code><b>public</b> <b>struct</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_AdminCap">AdminCap</a> <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_Vault"></a>

## Struct `Vault`



<pre><code><b>public</b> <b>struct</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a> <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>nbtc_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;(nbtc=0x0)::nbtc::NBTC&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>sui_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>price_per_nbtc_satoshi_in_mist: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>admin: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_is_paused">is_paused</a>: bool</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="(nbtc_swap=0x0)_nbtc_swap_EvaultPaused"></a>



<pre><code><b>const</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_EvaultPaused">EvaultPaused</a>: u64 = 1;
</code></pre>



<a name="(nbtc_swap=0x0)_nbtc_swap_EInsufficientLiquidity"></a>



<pre><code><b>const</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_EInsufficientLiquidity">EInsufficientLiquidity</a>: u64 = 2;
</code></pre>



<a name="(nbtc_swap=0x0)_nbtc_swap_EInvalidPrice"></a>



<pre><code><b>const</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_EInvalidPrice">EInvalidPrice</a>: u64 = 3;
</code></pre>



<a name="(nbtc_swap=0x0)_nbtc_swap_EInsufficientSuiPayment"></a>



<pre><code><b>const</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_EInsufficientSuiPayment">EInsufficientSuiPayment</a>: u64 = 4;
</code></pre>



<a name="(nbtc_swap=0x0)_nbtc_swap_PRICE_CONVERSION_FACTOR"></a>



<pre><code><b>const</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_PRICE_CONVERSION_FACTOR">PRICE_CONVERSION_FACTOR</a>: u64 = 10;
</code></pre>



<a name="(nbtc_swap=0x0)_nbtc_swap_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_init">init</a>(ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <b>let</b> initial_price = 25000; //25k SUI per NBTC
    <b>let</b> sender = tx_context::sender(ctx);
    transfer::transfer(
        <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_AdminCap">AdminCap</a> {
            id: object::new(ctx),
        },
        sender,
    );
    <b>let</b> vault = <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a> {
        id: object::new(ctx),
        nbtc_balance: coin::zero&lt;NBTC&gt;(ctx).into_balance(),
        sui_balance: coin::zero&lt;SUI&gt;(ctx).into_balance(),
        price_per_nbtc_satoshi_in_mist: <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_calculate_price">calculate_price</a>(initial_price),
        admin: sender,
        <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_is_paused">is_paused</a>: <b>false</b>,
    };
    transfer::share_object(vault);
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_calculate_price"></a>

## Function `calculate_price`



<pre><code><b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_calculate_price">calculate_price</a>(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_price">price</a>: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_calculate_price">calculate_price</a>(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_price">price</a>: u64): u64 {
    <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_price">price</a>  * <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_PRICE_CONVERSION_FACTOR">PRICE_CONVERSION_FACTOR</a>
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_swap_sui_for_nbtc"></a>

## Function `swap_sui_for_nbtc`



<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_swap_sui_for_nbtc">swap_sui_for_nbtc</a>(vault: &<b>mut</b> (<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::Vault, coin: <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_swap_sui_for_nbtc">swap_sui_for_nbtc</a>(vault: &<b>mut</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a>, coin: Coin&lt;SUI&gt;, ctx: &<b>mut</b> TxContext) {
    <b>assert</b>!(!vault.<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_is_paused">is_paused</a>, <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_EvaultPaused">EvaultPaused</a>);
    <b>let</b> sender = tx_context::sender(ctx);
    <b>let</b> sui_paid = coin.into_balance();
    <b>let</b> nbtc_to_receive = sui_paid.value() / vault.price_per_nbtc_satoshi_in_mist;
    <b>assert</b>!(nbtc_to_receive &gt; 0, <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_EInsufficientSuiPayment">EInsufficientSuiPayment</a>);
    vault.sui_balance.join(sui_paid);
    <b>let</b> vault_nbtc_balance = vault.nbtc_balance.value();
    <b>assert</b>!(vault_nbtc_balance &gt;= nbtc_to_receive, <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_EInsufficientLiquidity">EInsufficientLiquidity</a>);
    <b>let</b> nbtc_to_send = coin::take(&<b>mut</b> vault.nbtc_balance, nbtc_to_receive, ctx);
    transfer::public_transfer(nbtc_to_send, sender);
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_add_nbtc_liquidity"></a>

## Function `add_nbtc_liquidity`



<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_add_nbtc_liquidity">add_nbtc_liquidity</a>(_cap: &(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::AdminCap, vault: &<b>mut</b> (<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::Vault, nbtc_coin: <a href="../dependencies/sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;(nbtc=0x0)::nbtc::NBTC&gt;, _ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_add_nbtc_liquidity">add_nbtc_liquidity</a>(
    _cap: &<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_AdminCap">AdminCap</a>,
    vault: &<b>mut</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a>,
    nbtc_coin: Coin&lt;NBTC&gt;,
    _ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> nbtc_added = nbtc_coin.into_balance();
    vault.nbtc_balance.join(nbtc_added);
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_withdraw"></a>

## Function `withdraw`



<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_withdraw">withdraw</a>(_cap: &(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::AdminCap, vault: &<b>mut</b> (<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::Vault, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_withdraw">withdraw</a>(_cap: &<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_AdminCap">AdminCap</a>, vault: &<b>mut</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> nbtc_amount = vault.nbtc_balance.value();
    <b>let</b> sui_amount = vault.sui_balance.value();
    <b>let</b> nbtc_to_withdraw = coin::take(&<b>mut</b> vault.nbtc_balance, nbtc_amount, ctx);
    <b>let</b> sui_to_withdraw = coin::take(&<b>mut</b> vault.sui_balance, sui_amount, ctx);
    transfer::public_transfer(nbtc_to_withdraw, vault.admin);
    transfer::public_transfer(sui_to_withdraw, vault.admin)
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_set_price"></a>

## Function `set_price`



<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_set_price">set_price</a>(_cap: &(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::AdminCap, vault: &<b>mut</b> (<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::Vault, new_price: u64, _ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_set_price">set_price</a>(
    _cap: &<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_AdminCap">AdminCap</a>,
    vault: &<b>mut</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a>,
    new_price: u64,
    _ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(new_price &gt; 0, <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_EInvalidPrice">EInvalidPrice</a>);
    vault.price_per_nbtc_satoshi_in_mist = <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_calculate_price">calculate_price</a>(new_price);
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_set_paused"></a>

## Function `set_paused`



<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_set_paused">set_paused</a>(_cap: &(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::AdminCap, vault: &<b>mut</b> (<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::Vault, pause: bool, _ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>entry</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_set_paused">set_paused</a>(_cap: &<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_AdminCap">AdminCap</a>, vault: &<b>mut</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a>, pause: bool, _ctx: &<b>mut</b> TxContext) {
    vault.<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_is_paused">is_paused</a> = pause;
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_price"></a>

## Function `price`



<pre><code><b>public</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_price">price</a>(vault: &(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::Vault): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_price">price</a>(vault: &<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a>): u64 {
    vault.price_per_nbtc_satoshi_in_mist
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_nbtc_liquidity"></a>

## Function `nbtc_liquidity`



<pre><code><b>public</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_nbtc_liquidity">nbtc_liquidity</a>(vault: &(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::Vault): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_nbtc_liquidity">nbtc_liquidity</a>(vault: &<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a>): u64 {
    balance::value(&vault.nbtc_balance)
}
</code></pre>



</details>

<a name="(nbtc_swap=0x0)_nbtc_swap_is_paused"></a>

## Function `is_paused`



<pre><code><b>public</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_is_paused">is_paused</a>(vault: &(<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap">nbtc_swap</a>=0x0)::nbtc_swap::Vault): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_is_paused">is_paused</a>(vault: &<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_Vault">Vault</a>): bool {
    vault.<a href="../nbtc_swap/nbtc_swap.md#(nbtc_swap=0x0)_nbtc_swap_is_paused">is_paused</a>
}
</code></pre>



</details>
