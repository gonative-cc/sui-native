
<a name="bitcoin_lib_bitcoin_lib"></a>

# Module `bitcoin_lib::bitcoin_lib`



-  [Struct `State`](#bitcoin_lib_bitcoin_lib_State)
-  [Constants](#@Constants_0)
-  [Function `init`](#bitcoin_lib_bitcoin_lib_init)
-  [Function `store`](#bitcoin_lib_bitcoin_lib_store)
-  [Function `spend`](#bitcoin_lib_bitcoin_lib_spend)
-  [Function `execute_block`](#bitcoin_lib_bitcoin_lib_execute_block)
-  [Function `validate_execution`](#bitcoin_lib_bitcoin_lib_validate_execution)
-  [Function `add_utxo`](#bitcoin_lib_bitcoin_lib_add_utxo)
-  [Function `spend_utxo`](#bitcoin_lib_bitcoin_lib_spend_utxo)
-  [Function `utxo_exists`](#bitcoin_lib_bitcoin_lib_utxo_exists)


<pre><code><b>use</b> <a href="../bitcoin_lib/block.md#bitcoin_lib_block">bitcoin_lib::block</a>;
<b>use</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_btc_encoding">bitcoin_lib::btc_encoding</a>;
<b>use</b> <a href="../bitcoin_lib/crypto.md#bitcoin_lib_crypto">bitcoin_lib::crypto</a>;
<b>use</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding">bitcoin_lib::encoding</a>;
<b>use</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils">bitcoin_lib::executor_utils</a>;
<b>use</b> <a href="../bitcoin_lib/header.md#bitcoin_lib_header">bitcoin_lib::header</a>;
<b>use</b> <a href="../bitcoin_lib/input.md#bitcoin_lib_input">bitcoin_lib::input</a>;
<b>use</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter">bitcoin_lib::interpreter</a>;
<b>use</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">bitcoin_lib::output</a>;
<b>use</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">bitcoin_lib::reader</a>;
<b>use</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160">bitcoin_lib::ripemd160</a>;
<b>use</b> <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash">bitcoin_lib::sighash</a>;
<b>use</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">bitcoin_lib::stack</a>;
<b>use</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">bitcoin_lib::tx</a>;
<b>use</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo">bitcoin_lib::utxo</a>;
<b>use</b> <a href="../bitcoin_lib/vector_utils.md#bitcoin_lib_vector_utils">bitcoin_lib::vector_utils</a>;
<b>use</b> <a href="../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../dependencies/std/hash.md#std_hash">std::hash</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../dependencies/sui/ecdsa_k1.md#sui_ecdsa_k1">sui::ecdsa_k1</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
</code></pre>



<a name="bitcoin_lib_bitcoin_lib_State"></a>

## Struct `State`

State stores the utxo set


<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a> <b>has</b> key, <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_store">store</a>
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
<code>utxos: <a href="../dependencies/sui/table.md#sui_table_Table">sui::table::Table</a>&lt;<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>height: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="bitcoin_lib_bitcoin_lib_ECoinbaseNotMature"></a>



<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_ECoinbaseNotMature">ECoinbaseNotMature</a>: vector&lt;u8&gt; = b"Coinbase <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a> is not spendable until it reaches maturity of 100 blocks";
</code></pre>



<a name="bitcoin_lib_bitcoin_lib_EInvalidTransaction"></a>



<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_EInvalidTransaction">EInvalidTransaction</a>: vector&lt;u8&gt; = b"Invalid transaction";
</code></pre>



<a name="bitcoin_lib_bitcoin_lib_EInvalidCoinbase"></a>



<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_EInvalidCoinbase">EInvalidCoinbase</a>: vector&lt;u8&gt; = b"Invalid coinbase transaction";
</code></pre>



<a name="bitcoin_lib_bitcoin_lib_EBlockEmpty"></a>



<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_EBlockEmpty">EBlockEmpty</a>: vector&lt;u8&gt; = b"Block cannot empty";
</code></pre>



<a name="bitcoin_lib_bitcoin_lib_EUTXOInvalid"></a>



<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_EUTXOInvalid">EUTXOInvalid</a>: vector&lt;u8&gt; = b"UTXO already <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_spend">spend</a>";
</code></pre>



<a name="bitcoin_lib_bitcoin_lib_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_init">init</a>(ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <b>let</b> state = <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a> {
        id: object::new(ctx),
        utxos: table::new&lt;OutPoint, Data&gt;(ctx),
        height: 0,
    };
    transfer::share_object(state);
}
</code></pre>



</details>

<a name="bitcoin_lib_bitcoin_lib_store"></a>

## Function `store`



<pre><code><b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_store">store</a>(state: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">bitcoin_lib::bitcoin_lib::State</a>, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>, coinbase: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_store">store</a>(state: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a>, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &Transaction, coinbase: bool) {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.outputs().length().do!(|index| {
        <b>let</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a> = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.output_at(index);
        <b>let</b> (outpoint, data) = <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new">utxo::new</a>(
            <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.tx_id(),
            index <b>as</b> u32,
            state.height,
            coinbase,
            *<a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>,
        );
        state.<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_add_utxo">add_utxo</a>(outpoint, data);
    })
}
</code></pre>



</details>

<a name="bitcoin_lib_bitcoin_lib_spend"></a>

## Function `spend`



<pre><code><b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_spend">spend</a>(s: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">bitcoin_lib::bitcoin_lib::State</a>, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_spend">spend</a>(s: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a>, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &Transaction) {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.inputs().do!(|<a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>| {
        <b>let</b> outpoint = <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new_outpoint">utxo::new_outpoint</a>(
            <a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>.tx_id(),
            le_bytes_to_u64(<a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>.vout()) <b>as</b> u32,
        );
        <b>let</b> height = s.height;
        s.<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_spend_utxo">spend_utxo</a>(outpoint, height);
    });
}
</code></pre>



</details>

<a name="bitcoin_lib_bitcoin_lib_execute_block"></a>

## Function `execute_block`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_execute_block">execute_block</a>(state: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">bitcoin_lib::bitcoin_lib::State</a>, raw_block: vector&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_execute_block">execute_block</a>(state: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a>, raw_block: vector&lt;u8&gt;) {
    <b>let</b> <a href="../bitcoin_lib/block.md#bitcoin_lib_block">block</a> = <a href="../bitcoin_lib/block.md#bitcoin_lib_block_new">block::new</a>(raw_block);
    <b>assert</b>!(!<a href="../bitcoin_lib/block.md#bitcoin_lib_block">block</a>.txns().is_empty(), <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_EBlockEmpty">EBlockEmpty</a>); // <a href="../bitcoin_lib/block.md#bitcoin_lib_block">block</a> should be empty
    <b>assert</b>!(<a href="../bitcoin_lib/block.md#bitcoin_lib_block">block</a>.txns()[0].is_coinbase(), <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_EInvalidCoinbase">EInvalidCoinbase</a>);
    // TODO: handle case tx_id is identical <b>for</b> coinbase
    state.<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_store">store</a>(&<a href="../bitcoin_lib/block.md#bitcoin_lib_block">block</a>.txns()[0], <b>true</b>);
    <b>let</b> <b>mut</b> i = 1;
    <b>while</b> (i &lt; <a href="../bitcoin_lib/block.md#bitcoin_lib_block">block</a>.txns().length()) {
        <b>let</b> txn = <a href="../bitcoin_lib/block.md#bitcoin_lib_block">block</a>.txns()[i];
        <b>assert</b>!(<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_validate_execution">validate_execution</a>(state, txn), <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_EInvalidTransaction">EInvalidTransaction</a>);
        state.<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_store">store</a>(&txn, <b>false</b>);
        state.<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_spend">spend</a>(&txn);
        i = i + 1;
    };
    state.height = state.height + 1;
}
</code></pre>



</details>

<a name="bitcoin_lib_bitcoin_lib_validate_execution"></a>

## Function `validate_execution`



<pre><code><b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_validate_execution">validate_execution</a>(state: &<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">bitcoin_lib::bitcoin_lib::State</a>, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_validate_execution">validate_execution</a>(state: &<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a>, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: Transaction): bool {
    <b>let</b> number_input = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.inputs().length();
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> <b>mut</b> result = <b>true</b>;
    <b>while</b> (i &lt; number_input) {
        <b>let</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a> = <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_new_with_data">stack::new_with_data</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.witness()[i].items());
        <b>let</b> outpoint = <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_from_input">utxo::from_input</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.input_at(i));
        <b>let</b> utxo_valid = state.<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_utxo_exists">utxo_exists</a>(outpoint);
        <b>assert</b>!(utxo_valid, <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_EUTXOInvalid">EUTXOInvalid</a>);
        <b>let</b> data = state.utxos.borrow(outpoint);
        // TODO: We only support P2WPKH now.
        // We will support more standard scripts.
        <b>let</b> pk = data.pkh();
        <b>let</b> script = create_p2wpkh_scriptcode(pk);
        <b>let</b> res = run(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>, <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>, script, i, data.<a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>().amount());
        <b>if</b> (!res.is_success()) {
            result = <b>false</b>;
            <b>break</b>
        };
        i = i + 1;
    };
    result
}
</code></pre>



</details>

<a name="bitcoin_lib_bitcoin_lib_add_utxo"></a>

## Function `add_utxo`

Adds a new UTXO to the set


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_add_utxo">add_utxo</a>(state: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">bitcoin_lib::bitcoin_lib::State</a>, outpoint: <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>, info: <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_add_utxo">add_utxo</a>(state: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a>, outpoint: OutPoint, info: Data) {
    state.utxos.add(outpoint, info);
}
</code></pre>



</details>

<a name="bitcoin_lib_bitcoin_lib_spend_utxo"></a>

## Function `spend_utxo`

Spends a UTXO checks for existence and coinbase maturity, removes it, and returns its Info


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_spend_utxo">spend_utxo</a>(state: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">bitcoin_lib::bitcoin_lib::State</a>, outpoint: <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>, current_block_height: u64): <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_spend_utxo">spend_utxo</a>(state: &<b>mut</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a>, outpoint: OutPoint, current_block_height: u64): Data {
    <b>let</b> utxo_info = state.utxos.borrow(outpoint);
    <b>if</b> (utxo_info.is_coinbase()) {
        <b>assert</b>!(current_block_height &gt;= utxo_info.height() + 100, <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_ECoinbaseNotMature">ECoinbaseNotMature</a>);
    };
    state.utxos.remove(outpoint)
}
</code></pre>



</details>

<a name="bitcoin_lib_bitcoin_lib_utxo_exists"></a>

## Function `utxo_exists`

Checks if a UTXO exists in the set


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_utxo_exists">utxo_exists</a>(state: &<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">bitcoin_lib::bitcoin_lib::State</a>, outpoint: <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_utxo_exists">utxo_exists</a>(state: &<a href="../bitcoin_lib/executor.md#bitcoin_lib_bitcoin_lib_State">State</a>, outpoint: OutPoint): bool {
    state.utxos.contains(outpoint)
}
</code></pre>



</details>
