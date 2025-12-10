<a name="(bitcoin_spv=0x0)_utils"></a>

# Module `(bitcoin_spv=0x0)::utils`

- [Constants](#@Constants_0)
- [Function `nth_element`](<#(bitcoin_spv=0x0)_utils_nth_element>)

<pre><code></code></pre>

<a name="@Constants_0"></a>

## Constants

<a name="(bitcoin_spv=0x0)_utils_EOutBoundIndex"></a>

=== Errors ===

<pre><code>#[error]
<b>const</b> <a href="../bitcoin_spv/utils.md#(bitcoin_spv=0x0)_utils_EOutBoundIndex">EOutBoundIndex</a>: vector&lt;u8&gt; = b"The index 'n' is out of bounds <b>for</b> the vector";
</code></pre>

<a name="(bitcoin_spv=0x0)_utils_nth_element"></a>

## Function `nth_element`

returns nth smallest element in the vector v.
NOTE: it mutates the vector v.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/utils.md#(bitcoin_spv=0x0)_utils_nth_element">nth_element</a>(v: &<b>mut</b> vector&lt;u32&gt;, n: u64): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_spv/utils.md#(bitcoin_spv=0x0)_utils_nth_element">nth_element</a>(v: &<b>mut</b> vector&lt;u32&gt;, n: u64): u32 {
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> len = v.length();
    <b>assert</b>!(n &lt; len, <a href="../bitcoin_spv/utils.md#(bitcoin_spv=0x0)_utils_EOutBoundIndex">EOutBoundIndex</a>);
    <b>while</b> (i &lt;= n) {
        <b>let</b> <b>mut</b> j = i + 1;
        <b>while</b> (j &lt; len) {
            <b>if</b> (v[i] &gt; v[j]) {
                v.swap(i, j);
            };
            j = j + 1;
        };
        i = i + 1;
    };
    v[n]
}
</code></pre>

</details>
