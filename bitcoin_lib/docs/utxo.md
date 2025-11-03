
<a name="bitcoin_lib_utxo"></a>

# Module `bitcoin_lib::utxo`



-  [Struct `OutPoint`](#bitcoin_lib_utxo_OutPoint)
-  [Struct `Data`](#bitcoin_lib_utxo_Data)
-  [Constants](#@Constants_0)
-  [Function `new_outpoint`](#bitcoin_lib_utxo_new_outpoint)
-  [Function `from_input`](#bitcoin_lib_utxo_from_input)
-  [Function `new_data`](#bitcoin_lib_utxo_new_data)
-  [Function `new`](#bitcoin_lib_utxo_new)
-  [Function `tx_id`](#bitcoin_lib_utxo_tx_id)
-  [Function `vout`](#bitcoin_lib_utxo_vout)
-  [Function `output`](#bitcoin_lib_utxo_output)
-  [Function `height`](#bitcoin_lib_utxo_height)
-  [Function `is_coinbase`](#bitcoin_lib_utxo_is_coinbase)
-  [Function `pkh`](#bitcoin_lib_utxo_pkh)


<pre><code><b>use</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding">bitcoin_lib::encoding</a>;
<b>use</b> <a href="../bitcoin_lib/input.md#bitcoin_lib_input">bitcoin_lib::input</a>;
<b>use</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">bitcoin_lib::output</a>;
<b>use</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">bitcoin_lib::reader</a>;
<b>use</b> <a href="../bitcoin_lib/vector_utils.md#bitcoin_lib_vector_utils">bitcoin_lib::vector_utils</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
</code></pre>



<a name="bitcoin_lib_utxo_OutPoint"></a>

## Struct `OutPoint`

We represent UTXOs as a map of {key: OutPoint, value: Data}
OutPoint is a name used to identify UTXO in bitcoind
OutPoint is a UTXO ID


<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">OutPoint</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>: vector&lt;u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>: u32</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="bitcoin_lib_utxo_Data"></a>

## Struct `Data`

Data is a UTXO value


<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">Data</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>: bool</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>: <a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="bitcoin_lib_utxo_OP_0"></a>



<pre><code><b>const</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OP_0">OP_0</a>: u8 = 0;
</code></pre>



<a name="bitcoin_lib_utxo_OP_DATA_20"></a>



<pre><code><b>const</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OP_DATA_20">OP_DATA_20</a>: u8 = 20;
</code></pre>



<a name="bitcoin_lib_utxo_new_outpoint"></a>

## Function `new_outpoint`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new_outpoint">new_outpoint</a>(<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>: vector&lt;u8&gt;, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>: u32): <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new_outpoint">new_outpoint</a>(<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>: vector&lt;u8&gt;, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>: u32): <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">OutPoint</a> {
    <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">OutPoint</a> { <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a> }
}
</code></pre>



</details>

<a name="bitcoin_lib_utxo_from_input"></a>

## Function `from_input`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_from_input">from_input</a>(<a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>: &<a href="../bitcoin_lib/input.md#bitcoin_lib_input_Input">bitcoin_lib::input::Input</a>): <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_from_input">from_input</a>(<a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>: &Input): <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">OutPoint</a> {
    <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">OutPoint</a> {
        <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>: <a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>.<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>(),
        <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>: le_bytes_to_u64(<a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>.<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>()) <b>as</b> u32,
    }
}
</code></pre>



</details>

<a name="bitcoin_lib_utxo_new_data"></a>

## Function `new_data`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new_data">new_data</a>(<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>: u64, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>: bool, <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>: <a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a>): <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new_data">new_data</a>(<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>: u64, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>: bool, <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>: Output): <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">Data</a> {
    <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">Data</a> { <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>, <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a> }
}
</code></pre>



</details>

<a name="bitcoin_lib_utxo_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new">new</a>(<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>: vector&lt;u8&gt;, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>: u32, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>: u64, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>: bool, <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>: <a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a>): (<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new">new</a>(
    <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>: vector&lt;u8&gt;,
    <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>: u32,
    <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>: u64,
    <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>: bool,
    <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>: Output,
): (<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">OutPoint</a>, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">Data</a>) {
    (<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new_outpoint">new_outpoint</a>(<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>), <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_new_data">new_data</a>(<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>, <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>, <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>))
}
</code></pre>



</details>

<a name="bitcoin_lib_utxo_tx_id"></a>

## Function `tx_id`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>(outpoint: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>): vector&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a>(outpoint: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">OutPoint</a>): vector&lt;u8&gt; { outpoint.<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_tx_id">tx_id</a> }
</code></pre>



</details>

<a name="bitcoin_lib_utxo_vout"></a>

## Function `vout`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>(outpoint: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">bitcoin_lib::utxo::OutPoint</a>): u32
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a>(outpoint: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OutPoint">OutPoint</a>): u32 { outpoint.<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_vout">vout</a> }
</code></pre>



</details>

<a name="bitcoin_lib_utxo_output"></a>

## Function `output`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>(data: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>): &<a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>(data: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">Data</a>): &Output {
    &data.<a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>
}
</code></pre>



</details>

<a name="bitcoin_lib_utxo_height"></a>

## Function `height`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>(data: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a>(data: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">Data</a>): u64 { data.<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_height">height</a> }
</code></pre>



</details>

<a name="bitcoin_lib_utxo_is_coinbase"></a>

## Function `is_coinbase`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>(data: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a>(data: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">Data</a>): bool { data.<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_is_coinbase">is_coinbase</a> }
</code></pre>



</details>

<a name="bitcoin_lib_utxo_pkh"></a>

## Function `pkh`

Extract pkh from witness program.


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_pkh">pkh</a>(data: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">bitcoin_lib::utxo::Data</a>): vector&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_pkh">pkh</a>(data: &<a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_Data">Data</a>): vector&lt;u8&gt; {
    // TODO: we should refactor data to Output friendly format.
    <b>let</b> script = data.<a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>().script_pubkey();
    <b>let</b> is_wphk =
        script.length() == 22 &&
        script[0] == <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OP_0">OP_0</a> &&
        script[1] == <a href="../bitcoin_lib/utxo.md#bitcoin_lib_utxo_OP_DATA_20">OP_DATA_20</a>;
    <b>if</b> (is_wphk) {
        vector_slice(&script, 2, 22)
    } <b>else</b> {
        vector[]
    }
}
</code></pre>



</details>
