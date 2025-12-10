<a name="bitcoin_lib_tx"></a>

# Module `bitcoin_lib::tx`

- [Struct `InputWitness`](#bitcoin_lib_tx_InputWitness)
- [Struct `Transaction`](#bitcoin_lib_tx_Transaction)
- [Constants](#@Constants_0)
- [Function `new_witness`](#bitcoin_lib_tx_new_witness)
- [Function `new`](#bitcoin_lib_tx_new)
- [Function `items`](#bitcoin_lib_tx_items)
- [Function `version`](#bitcoin_lib_tx_version)
- [Function `inputs`](#bitcoin_lib_tx_inputs)
- [Function `outputs`](#bitcoin_lib_tx_outputs)
- [Function `witness`](#bitcoin_lib_tx_witness)
- [Function `locktime`](#bitcoin_lib_tx_locktime)
- [Function `input_at`](#bitcoin_lib_tx_input_at)
- [Function `output_at`](#bitcoin_lib_tx_output_at)
- [Function `is_witness`](#bitcoin_lib_tx_is_witness)
- [Function `tx_id`](#bitcoin_lib_tx_tx_id)
- [Function `set_witness`](#bitcoin_lib_tx_set_witness)
- [Function `deserialize`](#bitcoin_lib_tx_deserialize)
- [Function `parse_tx`](#bitcoin_lib_tx_parse_tx)
- [Function `is_coinbase`](#bitcoin_lib_tx_is_coinbase)
- [Function `new_unsign_segwit_tx`](#bitcoin_lib_tx_new_unsign_segwit_tx)
- [Function `serialize_segwit`](#bitcoin_lib_tx_serialize_segwit)

<pre><code><b>use</b> <a href="../bitcoin_lib/crypto.md#bitcoin_lib_crypto">bitcoin_lib::crypto</a>;
<b>use</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding">bitcoin_lib::encoding</a>;
<b>use</b> <a href="../bitcoin_lib/input.md#bitcoin_lib_input">bitcoin_lib::input</a>;
<b>use</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">bitcoin_lib::output</a>;
<b>use</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">bitcoin_lib::reader</a>;
<b>use</b> <a href="../bitcoin_lib/vector_utils.md#bitcoin_lib_vector_utils">bitcoin_lib::vector_utils</a>;
<b>use</b> <a href="../dependencies/std/hash.md#std_hash">std::hash</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
</code></pre>

<a name="bitcoin_lib_tx_InputWitness"></a>

## Struct `InputWitness`

<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">InputWitness</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>

<details>
<summary>Fields</summary>

<dl>
<dt>
<code><a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>: vector&lt;vector&lt;u8&gt;&gt;</code>
</dt>
<dd>
</dd>
</dl>

</details>

<a name="bitcoin_lib_tx_Transaction"></a>

## Struct `Transaction`

BTC transaction

<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>

<details>
<summary>Fields</summary>

<dl>
<dt>
<code><a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>: vector&lt;u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>: vector&lt;<a href="../bitcoin_lib/input.md#bitcoin_lib_input_Input">bitcoin_lib::input::Input</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>marker: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>flag: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>: vector&lt;<a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>: vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">bitcoin_lib::tx::InputWitness</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>: vector&lt;u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>: vector&lt;u8&gt;</code>
</dt>
<dd>
</dd>
</dl>

</details>

<a name="@Constants_0"></a>

## Constants

<a name="bitcoin_lib_tx_ETxReaderHasRemainingData"></a>

<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_ETxReaderHasRemainingData">ETxReaderHasRemainingData</a>: vector&lt;u8&gt; = b"Reader <b>has</b> remaining data";
</code></pre>

<a name="bitcoin_lib_tx_new_witness"></a>

## Function `new_witness`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_new_witness">new_witness</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>: vector&lt;vector&lt;u8&gt;&gt;): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">bitcoin_lib::tx::InputWitness</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_new_witness">new_witness</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>: vector&lt;vector&lt;u8&gt;&gt;): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">InputWitness</a> {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">InputWitness</a> {
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>,
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_new"></a>

## Function `new`

Create a btc data

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_new">new</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>: vector&lt;u8&gt;, marker: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u8&gt;, flag: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u8&gt;, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>: vector&lt;<a href="../bitcoin_lib/input.md#bitcoin_lib_input_Input">bitcoin_lib::input::Input</a>&gt;, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>: vector&lt;<a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a>&gt;, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>: vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">bitcoin_lib::tx::InputWitness</a>&gt;, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>: vector&lt;u8&gt;, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>: vector&lt;u8&gt;): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_new">new</a>(
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>: vector&lt;u8&gt;,
    marker: Option&lt;u8&gt;,
    flag: Option&lt;u8&gt;,
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>: vector&lt;Input&gt;,
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>: vector&lt;Output&gt;,
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>: vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">InputWitness</a>&gt;,
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>: vector&lt;u8&gt;,
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>: vector&lt;u8&gt;,
): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a> {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a> {
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>,
        marker,
        flag,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>,
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_items"></a>

## Function `items`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>(w: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">bitcoin_lib::tx::InputWitness</a>): vector&lt;vector&lt;u8&gt;&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>(w: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">InputWitness</a>): vector&lt;vector&lt;u8&gt;&gt; {
    w.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_version"></a>

## Function `version`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): vector&lt;u8&gt; {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_inputs"></a>

## Function `inputs`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): vector&lt;<a href="../bitcoin_lib/input.md#bitcoin_lib_input_Input">bitcoin_lib::input::Input</a>&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): vector&lt;Input&gt; {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_outputs"></a>

## Function `outputs`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): vector&lt;<a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a>&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): vector&lt;Output&gt; {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_witness"></a>

## Function `witness`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">bitcoin_lib::tx::InputWitness</a>&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">InputWitness</a>&gt; {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_locktime"></a>

## Function `locktime`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): vector&lt;u8&gt; {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_input_at"></a>

## Function `input_at`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_input_at">input_at</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>, idx: u64): &<a href="../bitcoin_lib/input.md#bitcoin_lib_input_Input">bitcoin_lib::input::Input</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_input_at">input_at</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>, idx: u64): &Input {
    &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>[idx]
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_output_at"></a>

## Function `output_at`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_output_at">output_at</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>, idx: u64): &<a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_output_at">output_at</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>, idx: u64): &Output {
    &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>[idx]
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_is_witness"></a>

## Function `is_witness`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_is_witness">is_witness</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): bool
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_is_witness">is_witness</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): bool {
    <b>if</b> (<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.marker.is_none() || <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.flag.is_none()) {
        <b>return</b> <b>false</b>
    };
    <b>let</b> m = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.marker.borrow();
    <b>let</b> f = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.flag.borrow();
    m == 0x00 && f == 0x01
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_tx_id"></a>

## Function `tx_id`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): vector&lt;u8&gt; {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_set_witness"></a>

## Function `set_witness`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_set_witness">set_witness</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<b>mut</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>: vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">bitcoin_lib::tx::InputWitness</a>&gt;)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_set_witness">set_witness</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<b>mut</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>: vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">InputWitness</a>&gt;) {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a> = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>;
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_deserialize"></a>

## Function `deserialize`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_deserialize">deserialize</a>(r: &<b>mut</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader_Reader">bitcoin_lib::reader::Reader</a>): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_deserialize">deserialize</a>(r: &<b>mut</b> Reader): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a> {
    <b>let</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a> = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_parse_tx">parse_tx</a>(r);
    <b>assert</b>!(r.end_stream(), <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_ETxReaderHasRemainingData">ETxReaderHasRemainingData</a>);
    <b>return</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_parse_tx"></a>

## Function `parse_tx`

deserialise transaction from bytes

<pre><code><b>public</b>(package) <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_parse_tx">parse_tx</a>(r: &<b>mut</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader_Reader">bitcoin_lib::reader::Reader</a>): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b>(package) <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_parse_tx">parse_tx</a>(r: &<b>mut</b> Reader): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a> {
    // transaction data without segwit.
    // <b>use</b> <b>for</b> compute the <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>
    <b>let</b> <b>mut</b> raw_tx = vector[];
    <b>let</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a> = r.read(4);
    raw_tx.append(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>);
    <b>let</b> segwit = r.peek(2);
    <b>let</b> <b>mut</b> marker: Option&lt;u8&gt; = option::none();
    <b>let</b> <b>mut</b> flag: Option&lt;u8&gt; = option::none();
    <b>if</b> (segwit[0] == 0x00 && segwit[1] == 0x01) {
        marker = option::some(r.read_byte());
        flag = option::some(r.read_byte());
    };
    <b>let</b> number_inputs = r.read_compact_size();
    raw_tx.append(u64_to_varint_bytes(number_inputs));
    <b>let</b> <b>mut</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a> = vector[];
    number_inputs.do!(|_| {
        <b>let</b> inp = <a href="../bitcoin_lib/input.md#bitcoin_lib_input_decode">input::decode</a>(r);
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>.push_back(
            inp,
        );
        raw_tx.append(inp.encode());
    });
    // read <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>
    <b>let</b> number_outputs = r.read_compact_size();
    raw_tx.append(u64_to_varint_bytes(number_outputs));
    <b>let</b> <b>mut</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a> = vector[];
    number_outputs.do!(|_| {
        <b>let</b> out = <a href="../bitcoin_lib/output.md#bitcoin_lib_output_decode">output::decode</a>(r);
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>.push_back(
            out,
        );
        raw_tx.append(out.encode());
    });
    // extract <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>
    <b>let</b> <b>mut</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a> = vector[];
    <b>if</b> (segwit[0] == 0x00 && segwit[1] == 0x01) {
        number_inputs.do!(|_| {
            <b>let</b> stack_item = r.read_compact_size();
            <b>let</b> <b>mut</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a> = vector[];
            stack_item.do!(|_| {
                <b>let</b> size = r.read_compact_size();
                <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>.push_back(r.read(size));
            });
            <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>.push_back(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_InputWitness">InputWitness</a> {
                <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>,
            });
        })
    };
    <b>let</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a> = r.read(4);
    raw_tx.append(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>);
    <b>let</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a> = hash256(raw_tx);
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_new">new</a>(
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>,
        marker,
        flag,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>,
    )
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_is_coinbase"></a>

## Function `is_coinbase`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_is_coinbase">is_coinbase</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): bool
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_is_coinbase">is_coinbase</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): bool {
    // TODO: check BIP34 and BIP141
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>.length() == 1 && <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>[0].vout() == x"ffffffff" &&
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>[0].<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>() ==  x"0000000000000000000000000000000000000000000000000000000000000000"
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_new_unsign_segwit_tx"></a>

## Function `new_unsign_segwit_tx`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_new_unsign_segwit_tx">new_unsign_segwit_tx</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>: vector&lt;<a href="../bitcoin_lib/input.md#bitcoin_lib_input_Input">bitcoin_lib::input::Input</a>&gt;, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>: vector&lt;<a href="../bitcoin_lib/output.md#bitcoin_lib_output_Output">bitcoin_lib::output::Output</a>&gt;): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_new_unsign_segwit_tx">new_unsign_segwit_tx</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>: vector&lt;Input&gt;, <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>: vector&lt;Output&gt;): <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a> {
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a> {
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>: x"02000000", // default <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a> <b>for</b> segwit
        marker: option::some(0),
        flag: option::some(1),
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>,
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>: vector[],
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>: x"00000000", // no lock time
        // TODO: Add method to compute <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>
        // in the current <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>, the transaction id only compute when we parse <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a> from bytes.
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_tx_id">tx_id</a>: vector::empty(),
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_tx_serialize_segwit"></a>

## Function `serialize_segwit`

Returns raw bytes of the btc tx. We only support segwit transaction

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_serialize_segwit">serialize_segwit</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_serialize_segwit">serialize_segwit</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">Transaction</a>): vector&lt;u8&gt; {
    <b>let</b> <b>mut</b> raw_tx = vector::empty&lt;u8&gt;();
    raw_tx.append(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_version">version</a>);
    raw_tx.push_back(*<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.marker.borrow());
    raw_tx.push_back(*<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.flag.borrow());
    <b>let</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a> = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>;
    raw_tx.append(u64_to_varint_bytes(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>.length()));
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_inputs">inputs</a>.do!(|inp| {
        raw_tx.append(inp.encode());
    });
    <b>let</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a> = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>;
    raw_tx.append(u64_to_varint_bytes(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>.length()));
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_outputs">outputs</a>.do!(|out| {
        raw_tx.append(out.encode());
    });
    <b>let</b> witnesses = <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>;
    witnesses.do!(|<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>| {
        raw_tx.append(u64_to_varint_bytes(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>.length()));
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_witness">witness</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_items">items</a>.do!(|element| {
            raw_tx.append(u64_to_varint_bytes(element.length()));
            raw_tx.append(element);
        });
    });
    raw_tx.append(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_locktime">locktime</a>);
    raw_tx
}
</code></pre>

</details>
