
<a name="bitcoin_lib_block"></a>

# Module `bitcoin_lib::block`



-  [Struct `Block`](#bitcoin_lib_block_Block)
-  [Function `new`](#bitcoin_lib_block_new)
-  [Function `txns`](#bitcoin_lib_block_txns)
-  [Function `header`](#bitcoin_lib_block_header)


<pre><code><b>use</b> <a href="../bitcoin_lib/crypto.md#bitcoin_lib_crypto">bitcoin_lib::crypto</a>;
<b>use</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding">bitcoin_lib::encoding</a>;
<b>use</b> <a href="../bitcoin_lib/header.md#bitcoin_lib_header">bitcoin_lib::header</a>;
<b>use</b> <a href="../bitcoin_lib/input.md#bitcoin_lib_input">bitcoin_lib::input</a>;
<b>use</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">bitcoin_lib::output</a>;
<b>use</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">bitcoin_lib::reader</a>;
<b>use</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">bitcoin_lib::tx</a>;
<b>use</b> <a href="../bitcoin_lib/vector_utils.md#bitcoin_lib_vector_utils">bitcoin_lib::vector_utils</a>;
<b>use</b> <a href="../dependencies/std/hash.md#std_hash">std::hash</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
</code></pre>



<a name="bitcoin_lib_block_Block"></a>

## Struct `Block`

A block is a collection of all transactions in the BTC block


<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/block.md#bitcoin_lib_block_Block">Block</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>block_header: <a href="../bitcoin_lib/header.md#bitcoin_lib_header_BlockHeader">bitcoin_lib::header::BlockHeader</a></code>
</dt>
<dd>
</dd>
<dt>
<code>transactions: vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="bitcoin_lib_block_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/block.md#bitcoin_lib_block_new">new</a>(raw_block: vector&lt;u8&gt;): <a href="../bitcoin_lib/block.md#bitcoin_lib_block_Block">bitcoin_lib::block::Block</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/block.md#bitcoin_lib_block_new">new</a>(raw_block: vector&lt;u8&gt;): <a href="../bitcoin_lib/block.md#bitcoin_lib_block_Block">Block</a> {
    <b>let</b> <b>mut</b> r = <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader_new">reader::new</a>(raw_block);
    <b>let</b> block_header = <a href="../bitcoin_lib/header.md#bitcoin_lib_header_new">header::new</a>(r.read(80));
    <b>let</b> number_tx = r.read_compact_size();
    <b>let</b> <b>mut</b> transactions = vector[];
    number_tx.do!(|_| {
        transactions.push_back(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_parse_tx">tx::parse_tx</a>(&<b>mut</b> r));
    });
    <a href="../bitcoin_lib/block.md#bitcoin_lib_block_Block">Block</a> {
        block_header,
        transactions,
    }
}
</code></pre>



</details>

<a name="bitcoin_lib_block_txns"></a>

## Function `txns`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/block.md#bitcoin_lib_block_txns">txns</a>(b: &<a href="../bitcoin_lib/block.md#bitcoin_lib_block_Block">bitcoin_lib::block::Block</a>): vector&lt;<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/block.md#bitcoin_lib_block_txns">txns</a>(b: &<a href="../bitcoin_lib/block.md#bitcoin_lib_block_Block">Block</a>): vector&lt;Transaction&gt; {
    b.transactions
}
</code></pre>



</details>

<a name="bitcoin_lib_block_header"></a>

## Function `header`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/header.md#bitcoin_lib_header">header</a>(b: &<a href="../bitcoin_lib/block.md#bitcoin_lib_block_Block">bitcoin_lib::block::Block</a>): <a href="../bitcoin_lib/header.md#bitcoin_lib_header_BlockHeader">bitcoin_lib::header::BlockHeader</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/header.md#bitcoin_lib_header">header</a>(b: &<a href="../bitcoin_lib/block.md#bitcoin_lib_block_Block">Block</a>): BlockHeader {
    b.block_header
}
</code></pre>



</details>
