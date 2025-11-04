<a name="bitcoin_lib_encoding"></a>

# Module `bitcoin_lib::encoding`

- [Constants](#@Constants_0)
- [Function `le_bytes_to_u64`](#bitcoin_lib_encoding_le_bytes_to_u64)
- [Function `u32_to_le_bytes`](#bitcoin_lib_encoding_u32_to_le_bytes)
- [Function `u64_to_le_bytes`](#bitcoin_lib_encoding_u64_to_le_bytes)
- [Function `u64_to_cscriptnum`](#bitcoin_lib_encoding_u64_to_cscriptnum)
- [Function `vector_true`](#bitcoin_lib_encoding_vector_true)
- [Function `vector_false`](#bitcoin_lib_encoding_vector_false)
- [Function `u64_to_varint_bytes`](#bitcoin_lib_encoding_u64_to_varint_bytes)
- [Function `script_to_var_bytes`](#bitcoin_lib_encoding_script_to_var_bytes)
- [Function `zerohash_32bytes`](#bitcoin_lib_encoding_zerohash_32bytes)
- [Function `der_int_to_32_bytes`](#bitcoin_lib_encoding_der_int_to_32_bytes)
- [Function `parse_der_encoded_int_value`](#bitcoin_lib_encoding_parse_der_encoded_int_value)
- [Function `parse_btc_sig`](#bitcoin_lib_encoding_parse_btc_sig)

<pre><code><b>use</b> <a href="../bitcoin_lib/vector_utils.md#bitcoin_lib_vector_utils">bitcoin_lib::vector_utils</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
</code></pre>

<a name="@Constants_0"></a>

## Constants

<a name="bitcoin_lib_encoding_EDerIntParsing"></a>

<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EDerIntParsing">EDerIntParsing</a>: vector&lt;u8&gt; = b"Error parsing DER to Int";
</code></pre>

<a name="bitcoin_lib_encoding_EBtcSigParsing"></a>

<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>: vector&lt;u8&gt; = b"Error parsing bitcoin signature";
</code></pre>

<a name="bitcoin_lib_encoding_EOverflowVector"></a>

<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EOverflowVector">EOverflowVector</a>: vector&lt;u8&gt; = b"Can't covert vector to u64 b/c overflow";
</code></pre>

<a name="bitcoin_lib_encoding_le_bytes_to_u64"></a>

## Function `le_bytes_to_u64`

Converts vector bytes in the little-endian form to a u64 integer

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_le_bytes_to_u64">le_bytes_to_u64</a>(v: vector&lt;u8&gt;): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_le_bytes_to_u64">le_bytes_to_u64</a>(v: vector&lt;u8&gt;): u64 {
    <b>assert</b>!(v.length() &lt;= 8, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EOverflowVector">EOverflowVector</a>);
    <b>let</b> <b>mut</b> number = 0;
    v.length().do!(|i| {
        number = number + ((v[i] <b>as</b> u64) * ((1 <b>as</b> u64) &lt;&lt; ((i <b>as</b> u8) * 8)) <b>as</b> u64)
    });
    number
}
</code></pre>

</details>

<a name="bitcoin_lib_encoding_u32_to_le_bytes"></a>

## Function `u32_to_le_bytes`

Converts a u32 integer to a 4-byte little-endian vector<u8>.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u32_to_le_bytes">u32_to_le_bytes</a>(val: u32): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u32_to_le_bytes">u32_to_le_bytes</a>(val: u32): vector&lt;u8&gt; {
    <b>let</b> <b>mut</b> bytes = vector::empty&lt;u8&gt;();
    bytes.push_back(((val &gt;&gt; 0) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 8) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 16) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 24) & 0xFF) <b>as</b> u8);
    bytes
}
</code></pre>

</details>

<a name="bitcoin_lib_encoding_u64_to_le_bytes"></a>

## Function `u64_to_le_bytes`

Converts a u64 integer to an 8-byte little-endian vector<u8>.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u64_to_le_bytes">u64_to_le_bytes</a>(val: u64): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u64_to_le_bytes">u64_to_le_bytes</a>(val: u64): vector&lt;u8&gt; {
    <b>let</b> <b>mut</b> bytes = vector::empty&lt;u8&gt;();
    bytes.push_back(((val &gt;&gt; 0) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 8) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 16) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 24) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 32) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 40) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 48) & 0xFF) <b>as</b> u8);
    bytes.push_back(((val &gt;&gt; 56) & 0xFF) <b>as</b> u8);
    bytes
}
</code></pre>

</details>

<a name="bitcoin_lib_encoding_u64_to_cscriptnum"></a>

## Function `u64_to_cscriptnum`

Converts u64 into the CScriptNum byte vector format.
This is the format expected to be pushed onto the stack.
https://github.com/bitcoin/bitcoin/blob/87ec923d3a7af7b30613174b41c6fb11671df466/src/script/script.h#L349

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u64_to_cscriptnum">u64_to_cscriptnum</a>(n: u64): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u64_to_cscriptnum">u64_to_cscriptnum</a>(n: u64): vector&lt;u8&gt; {
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

<a name="bitcoin_lib_encoding_vector_true"></a>

## Function `vector_true`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_vector_true">vector_true</a>(): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_vector_true">vector_true</a>(): vector&lt;u8&gt; { vector[0x01] }
</code></pre>

</details>

<a name="bitcoin_lib_encoding_vector_false"></a>

## Function `vector_false`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_vector_false">vector_false</a>(): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_vector_false">vector_false</a>(): vector&lt;u8&gt; { vector[] }
</code></pre>

</details>

<a name="bitcoin_lib_encoding_u64_to_varint_bytes"></a>

## Function `u64_to_varint_bytes`

Encodes a u64 into VarInt format.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u64_to_varint_bytes">u64_to_varint_bytes</a>(n: u64): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u64_to_varint_bytes">u64_to_varint_bytes</a>(n: u64): vector&lt;u8&gt; {
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

<a name="bitcoin_lib_encoding_script_to_var_bytes"></a>

## Function `script_to_var_bytes`

Prepends the VarInt encoding of the script len to the script.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_script_to_var_bytes">script_to_var_bytes</a>(script: &vector&lt;u8&gt;): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_script_to_var_bytes">script_to_var_bytes</a>(script: &vector&lt;u8&gt;): vector&lt;u8&gt; {
    <b>let</b> len = script.length();
    <b>let</b> <b>mut</b> result = <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_u64_to_varint_bytes">u64_to_varint_bytes</a>(len);
    result.append(*script);
    result
}
</code></pre>

</details>

<a name="bitcoin_lib_encoding_zerohash_32bytes"></a>

## Function `zerohash_32bytes`

Returns a vector with 32 zero bytes.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_zerohash_32bytes">zerohash_32bytes</a>(): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_zerohash_32bytes">zerohash_32bytes</a>(): vector&lt;u8&gt; {
    vector::tabulate!(32, |_| 0)
}
</code></pre>

</details>

<a name="bitcoin_lib_encoding_der_int_to_32_bytes"></a>

## Function `der_int_to_32_bytes`

Parses a DER-encoded positvie integer value (r or s) to 32-byte vector

<pre><code><b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_der_int_to_32_bytes">der_int_to_32_bytes</a>(val_bytes: &vector&lt;u8&gt;): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_der_int_to_32_bytes">der_int_to_32_bytes</a>(val_bytes: &vector&lt;u8&gt;): vector&lt;u8&gt; {
    <b>let</b> len = val_bytes.length();
    <b>assert</b>!(len &gt; 0 && len &lt;= 33, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EDerIntParsing">EDerIntParsing</a>);
    <b>let</b> offset;
    <b>let</b> <b>mut</b> value_len = 32;
    <b>if</b> (len == 33) {
        // prefix 0x00
        <b>assert</b>!(val_bytes[0] == 0x00, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EDerIntParsing">EDerIntParsing</a>);
        <b>assert</b>!(val_bytes[1] & 0x80 != 0, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EDerIntParsing">EDerIntParsing</a>);
        // check <b>if</b> MSB od second byte is 1, <b>else</b> wrong padding
        offset = 1; // skip 0x00
    } <b>else</b> <b>if</b> (len == 32) {
        // no prefix
        offset = 0;
    } <b>else</b> {
        // padding needed
        <b>assert</b>!(!(val_bytes[0] == 0x00 && len &gt; 1), <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EDerIntParsing">EDerIntParsing</a>); // wrong leading 0x00 <b>for</b> short number
        offset = 0;
        value_len = len;
    };
    <b>let</b> <b>mut</b> result_32_bytes = vector::empty&lt;u8&gt;();
    <b>let</b> num_padding_zeros = 32 - value_len;
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; num_padding_zeros) {
        result_32_bytes.push_back(0x00);
        i = i + 1;
    };
    i = 0;
    <b>while</b> (i &lt; value_len) {
        result_32_bytes.push_back(val_bytes[offset+i]);
        i = i + 1;
    };
    result_32_bytes
}
</code></pre>

</details>

<a name="bitcoin_lib_encoding_parse_der_encoded_int_value"></a>

## Function `parse_der_encoded_int_value`

Parses a single DER-encoded INT from der_bytes at the current cursor and modifies the cursor.

<pre><code><b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_parse_der_encoded_int_value">parse_der_encoded_int_value</a>(der_bytes: &vector&lt;u8&gt;, cursor: &<b>mut</b> u64, der_len: u64): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_parse_der_encoded_int_value">parse_der_encoded_int_value</a>(
    der_bytes: &vector&lt;u8&gt;,
    cursor: &<b>mut</b> u64,
    der_len: u64,
): vector&lt;u8&gt; {
    <b>assert</b>!(*cursor &lt; der_len && der_bytes[*cursor] == 0x02, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    *cursor = *cursor + 1;
    <b>assert</b>!(*cursor &lt; der_len, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    <b>let</b> component_len = (der_bytes[*cursor] <b>as</b> u64);
    *cursor = *cursor + 1;
    <b>assert</b>!(component_len &gt; 0 && *cursor + component_len &lt;= der_len, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    <b>let</b> value_der_bytes = <a href="../bitcoin_lib/vector_utils.md#bitcoin_lib_vector_utils_vector_slice">vector_utils::vector_slice</a>(
        der_bytes,
        *cursor,
        *cursor + component_len,
    );
    *cursor = *cursor + component_len;
    value_der_bytes
}
</code></pre>

</details>

<a name="bitcoin_lib_encoding_parse_btc_sig"></a>

## Function `parse_btc_sig`

Parses a DER encoded Bitcoin signature (r,s + sighash flag)
Returns a tuple containing the 64-byte concat(r,s) and sighash_flag.

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_parse_btc_sig">parse_btc_sig</a>(full_sig_from_stack: &<b>mut</b> vector&lt;u8&gt;): (vector&lt;u8&gt;, u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_parse_btc_sig">parse_btc_sig</a>(full_sig_from_stack: &<b>mut</b> vector&lt;u8&gt;): (vector&lt;u8&gt;, u8) {
    // TODO: <b>use</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">reader</a> <b>module</b>
    <b>let</b> total_len = full_sig_from_stack.length();
    <b>assert</b>!(total_len &gt;= 8 && total_len &lt;= 73, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    <b>let</b> sighash_flag = full_sig_from_stack.pop_back();
    <b>let</b> der_bytes = full_sig_from_stack;
    <b>let</b> der_len = der_bytes.length();
    <b>assert</b>!(der_len &gt; 0, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    <b>let</b> <b>mut</b> cursor = 0;
    // SEQUENCE tag (0x30)
    <b>assert</b>!(cursor &lt; der_len && der_bytes[cursor] == 0x30, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    cursor = cursor + 1;
    <b>assert</b>!(cursor &lt; der_len, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    <b>let</b> seq_len = (der_bytes[cursor] <b>as</b> u64);
    cursor = cursor + 1;
    <b>assert</b>!(seq_len == der_len - cursor, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    // Parse R
    <b>let</b> r_value_der = <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_parse_der_encoded_int_value">parse_der_encoded_int_value</a>(der_bytes, &<b>mut</b> cursor, der_len);
    <b>let</b> r_32_bytes = <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_der_int_to_32_bytes">der_int_to_32_bytes</a>(&r_value_der);
    // Parse S
    <b>let</b> s_value_der = <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_parse_der_encoded_int_value">parse_der_encoded_int_value</a>(der_bytes, &<b>mut</b> cursor, der_len);
    <b>let</b> s_32_bytes = <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_der_int_to_32_bytes">der_int_to_32_bytes</a>(&s_value_der);
    <b>assert</b>!(cursor == der_len, <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding_EBtcSigParsing">EBtcSigParsing</a>);
    // concat (r,s)
    <b>let</b> <b>mut</b> r_and_s_bytes = r_32_bytes;
    r_and_s_bytes.append(s_32_bytes);
    (r_and_s_bytes, sighash_flag)
}
</code></pre>

</details>
