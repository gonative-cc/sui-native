
<a name="(bitcoin_spv=0x0)_light_block"></a>

# Module `(bitcoin_spv=0x0)::light_block`



-  [Struct `LightBlock`](#(bitcoin_spv=0x0)_light_block_LightBlock)
-  [Function `new_light_block`](#(bitcoin_spv=0x0)_light_block_new_light_block)
-  [Function `height`](#(bitcoin_spv=0x0)_light_block_height)
-  [Function `header`](#(bitcoin_spv=0x0)_light_block_header)
-  [Function `chain_work`](#(bitcoin_spv=0x0)_light_block_chain_work)


<pre><code><b>use</b> (bitcoin_parser=0x0)::crypto;
<b>use</b> (bitcoin_parser=0x0)::encoding;
<b>use</b> (bitcoin_parser=0x0)::<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>;
<b>use</b> (bitcoin_parser=0x0)::reader;
<b>use</b> <a href="../dependencies/std/hash.md#std_hash">std::hash</a>;
</code></pre>



<a name="(bitcoin_spv=0x0)_light_block_LightBlock"></a>

## Struct `LightBlock`



<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">LightBlock</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_height">height</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_chain_work">chain_work</a>: u256</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>: (bitcoin_spv=0x0)::header::BlockHeader</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="(bitcoin_spv=0x0)_light_block_new_light_block"></a>

## Function `new_light_block`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_new_light_block">new_light_block</a>(<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_height">height</a>: u64, <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>: (bitcoin_spv=0x0)::header::BlockHeader, <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_chain_work">chain_work</a>: u256): (bitcoin_spv=0x0)::<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">light_block::LightBlock</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_new_light_block">new_light_block</a>(<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_height">height</a>: u64, <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>: BlockHeader, <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_chain_work">chain_work</a>: u256): <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">LightBlock</a> {
    <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">LightBlock</a> {
        <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_height">height</a>,
        <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_chain_work">chain_work</a>,
        <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>: <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>,
    }
}
</code></pre>



</details>

<a name="(bitcoin_spv=0x0)_light_block_height"></a>

## Function `height`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_height">height</a>(lb: &(bitcoin_spv=0x0)::<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">light_block::LightBlock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_height">height</a>(lb: &<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">LightBlock</a>): u64 {
    lb.<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_height">height</a>
}
</code></pre>



</details>

<a name="(bitcoin_spv=0x0)_light_block_header"></a>

## Function `header`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>(lb: &(bitcoin_spv=0x0)::<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">light_block::LightBlock</a>): &(bitcoin_spv=0x0)::header::BlockHeader
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>(lb: &<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">LightBlock</a>): &BlockHeader {
    &lb.<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_header">header</a>
}
</code></pre>



</details>

<a name="(bitcoin_spv=0x0)_light_block_chain_work"></a>

## Function `chain_work`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_chain_work">chain_work</a>(lb: &(bitcoin_spv=0x0)::<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">light_block::LightBlock</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_chain_work">chain_work</a>(lb: &<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_LightBlock">LightBlock</a>): u256 {
    lb.<a href="../bitcoin_spv/light_block.md#(bitcoin_spv=0x0)_light_block_chain_work">chain_work</a>
}
</code></pre>



</details>
