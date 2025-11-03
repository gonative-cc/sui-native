<a name="bitcoin_lib_executor_utils"></a>

# Module `bitcoin_lib::executor_utils`

- [Function `u64_to_cscriptnum`](#bitcoin_lib_executor_utils_u64_to_cscriptnum)
- [Function `vector_true`](#bitcoin_lib_executor_utils_vector_true)
- [Function `vector_false`](#bitcoin_lib_executor_utils_vector_false)
- [Function `u64_to_varint_bytes`](#bitcoin_lib_executor_utils_u64_to_varint_bytes)
- [Function `script_to_var_bytes`](#bitcoin_lib_executor_utils_script_to_var_bytes)
- [Function `zerohash_32bytes`](#bitcoin_lib_executor_utils_zerohash_32bytes)

<pre><code><b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
</code></pre>

<a name="bitcoin_lib_executor_utils_u64_to_cscriptnum"></a>

## Function `u64_to_cscriptnum`

Converts u64 into the CScriptNum byte vector format.
This is the format expected to be pushed onto the stack.
https://github.com/bitcoin/bitcoin/blob/87ec923d3a7af7b30613174b41c6fb11671df466/src/script/script.h#L349

<pre><code><b>public</b>(package) <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_u64_to_cscriptnum">u64_to_cscriptnum</a>(n: u64): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b>(package) <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_u64_to_cscriptnum">u64_to_cscriptnum</a>(n: u64): vector&lt;u8&gt; {
    <b>let</b> <b>mut</b> result_bytes = vector::empty&lt;u8&gt;();
    <b>if</b> (n == 0) {
        <b>return</b> result_bytes // 0 is represented by empty vector
    };
    <b>let</b> <b>mut</b> n = n;
    // convert to little endian
    <b>while</b> (n &gt; 0) {
        result_bytes.push_back((n & 0xff) <b>as</b> u8);
        n = n &gt;&gt; 8;
    };
    // padding
    <b>if</b> (result_bytes.length() &gt; 0) {
        <b>let</b> last_index = result_bytes.length() -1;
        <b>let</b> last_byte = *result_bytes.borrow(last_index);
        <b>if</b> ((last_byte & 0x80) != 0) {
            result_bytes.push_back(0x00);
        }
    };
    result_bytes
}
</code></pre>

</details>

<a name="bitcoin_lib_executor_utils_vector_true"></a>

## Function `vector_true`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_vector_true">vector_true</a>(): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_vector_true">vector_true</a>(): vector&lt;u8&gt; { vector[0x01] }
</code></pre>

</details>

<a name="bitcoin_lib_executor_utils_vector_false"></a>

## Function `vector_false`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_vector_false">vector_false</a>(): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_vector_false">vector_false</a>(): vector&lt;u8&gt; { vector[] }
</code></pre>

</details>

<a name="bitcoin_lib_executor_utils_u64_to_varint_bytes"></a>

## Function `u64_to_varint_bytes`

Encodes a u64 into VarInt format.
Adapted from go_native/move_spv_light_client

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_u64_to_varint_bytes">u64_to_varint_bytes</a>(n: u64): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_u64_to_varint_bytes">u64_to_varint_bytes</a>(n: u64): vector&lt;u8&gt; {
    <b>let</b> <b>mut</b> ans = vector::empty&lt;u8&gt;();
    <b>let</b> <b>mut</b> n = n;
    <b>if</b> (n &lt;= 252) {
        ans.push_back(n <b>as</b> u8);
    } <b>else</b> <b>if</b> (n &lt;= 65535) {
        ans.push_back(0xfd);
        do!(2, |_i| {
            ans.push_back((n & 0xff) <b>as</b> u8);
            n = n &gt;&gt; 8;
        });
    } <b>else</b> <b>if</b> (n &lt;= 4294967295) {
        ans.push_back(0xfe);
        do!(4, |_i| {
            ans.push_back((n & 0xff) <b>as</b> u8);
            n = n &gt;&gt; 8;
        });
    } <b>else</b> {
        ans.push_back(0xff);
        do!(8, |_i| {
            ans.push_back((n & 0xff) <b>as</b> u8);
            n = n &gt;&gt; 8;
        });
    };
    ans
}
</code></pre>

</details>

<a name="bitcoin_lib_executor_utils_script_to_var_bytes"></a>

## Function `script_to_var_bytes`

Prepends the VarInt encoding of the script len to the script.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_script_to_var_bytes">script_to_var_bytes</a>(script: &vector&lt;u8&gt;): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_script_to_var_bytes">script_to_var_bytes</a>(script: &vector&lt;u8&gt;): vector&lt;u8&gt; {
    <b>let</b> len = script.length();
    <b>let</b> <b>mut</b> result = <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_u64_to_varint_bytes">u64_to_varint_bytes</a>(len);
    result.append(*script);
    result
}
</code></pre>

</details>

<a name="bitcoin_lib_executor_utils_zerohash_32bytes"></a>

## Function `zerohash_32bytes`

Returns a vector with 32 zero bytes.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_zerohash_32bytes">zerohash_32bytes</a>(): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_zerohash_32bytes">zerohash_32bytes</a>(): vector&lt;u8&gt; {
    vector::tabulate!(32, |_| 0)
}
</code></pre>

</details>
