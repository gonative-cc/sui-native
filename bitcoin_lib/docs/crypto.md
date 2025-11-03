<a name="bitcoin_lib_crypto"></a>

# Module `bitcoin_lib::crypto`

- [Function `hash256`](#bitcoin_lib_crypto_hash256)

<pre><code><b>use</b> <a href="../dependencies/std/hash.md#std_hash">std::hash</a>;
</code></pre>

<a name="bitcoin_lib_crypto_hash256"></a>

## Function `hash256`

Computes sha2_256(sha2_256(data)).

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/crypto.md#bitcoin_lib_crypto_hash256">hash256</a>(data: vector&lt;u8&gt;): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/crypto.md#bitcoin_lib_crypto_hash256">hash256</a>(data: vector&lt;u8&gt;): vector&lt;u8&gt; {
    sha2_256(sha2_256(data))
}
</code></pre>

</details>
