<a name="bitcoin_lib_sighash"></a>

# Module `bitcoin_lib::sighash`

- [Constants](#@Constants_0)
- [Function `create_segwit_preimage`](#bitcoin_lib_sighash_create_segwit_preimage)

<pre><code><b>use</b> <a href="../bitcoin_lib/crypto.md#bitcoin_lib_crypto">bitcoin_lib::crypto</a>;
<b>use</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding">bitcoin_lib::encoding</a>;
<b>use</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils">bitcoin_lib::executor_utils</a>;
<b>use</b> <a href="../bitcoin_lib/input.md#bitcoin_lib_input">bitcoin_lib::input</a>;
<b>use</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">bitcoin_lib::output</a>;
<b>use</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">bitcoin_lib::reader</a>;
<b>use</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">bitcoin_lib::tx</a>;
<b>use</b> <a href="../bitcoin_lib/vector_utils.md#bitcoin_lib_vector_utils">bitcoin_lib::vector_utils</a>;
<b>use</b> <a href="../dependencies/std/hash.md#std_hash">std::hash</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
</code></pre>

<a name="@Constants_0"></a>

## Constants

<a name="bitcoin_lib_sighash_SIGHASH_ALL"></a>

Sighash types

<pre><code><b>const</b> <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_ALL">SIGHASH_ALL</a>: u8 = 1;
</code></pre>

<a name="bitcoin_lib_sighash_SIGHASH_NONE"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_NONE">SIGHASH_NONE</a>: u8 = 2;
</code></pre>

<a name="bitcoin_lib_sighash_SIGHASH_SINGLE"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_SINGLE">SIGHASH_SINGLE</a>: u8 = 3;
</code></pre>

<a name="bitcoin_lib_sighash_SIGHASH_ANYONECANPAY_FLAG"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_ANYONECANPAY_FLAG">SIGHASH_ANYONECANPAY_FLAG</a>: u8 = 128;
</code></pre>

<a name="bitcoin_lib_sighash_create_segwit_preimage"></a>

## Function `create_segwit_preimage`

Constructs the BIP143 preimage for the Segwit hash signature.
https://learnmeabitcoin.com/technical/keys/signature/ -> Segwit Algorithm

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_create_segwit_preimage">create_segwit_preimage</a>(transaction: &<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>, input_idx_to_sign: u64, input_script: &vector&lt;u8&gt;, amount_spent_by_this_input: vector&lt;u8&gt;, sighash_type: u8): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_create_segwit_preimage">create_segwit_preimage</a>(
    transaction: &Transaction,
    input_idx_to_sign: u64,
    input_script: &vector&lt;u8&gt;, // For P2WPKH: 0x1976a914{PKH}88ac. For P2WSH: the witnessScript.
    amount_spent_by_this_input: vector&lt;u8&gt;,
    sighash_type: u8,
): vector&lt;u8&gt; {
    <b>let</b> <b>mut</b> preimage = vector[];
    preimage.append(transaction.version());
    // HASH256(concatenation of all (<a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>.tx_id + <a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>.vout))
    <b>let</b> hash_prevouts: vector&lt;u8&gt; = <b>if</b> ((sighash_type & <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_ANYONECANPAY_FLAG">SIGHASH_ANYONECANPAY_FLAG</a>) == 0) {
        <b>let</b> <b>mut</b> all_prevouts_concat = vector[];
        transaction.inputs().length().do!(|i| {
            <b>let</b> input_ref = transaction.input_at(i);
            all_prevouts_concat.append(input_ref.tx_id()); //already a u32_le_bytes
            all_prevouts_concat.append(input_ref.vout());
        });
        hash256(all_prevouts_concat)
    } <b>else</b> {
        <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_zerohash_32bytes">executor_utils::zerohash_32bytes</a>() // 32 zero bytes <b>if</b> ANYONECANPAY
    };
    preimage.append(hash_prevouts);
    // HASH256(concatenation of all <a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a>.sequence)
    <b>let</b> base_sighash_type = sighash_type & 0x1f; // Mask off ANYONECANPAY bit
    <b>let</b> hash_sequence = <b>if</b> (
        (sighash_type & <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_ANYONECANPAY_FLAG">SIGHASH_ANYONECANPAY_FLAG</a>) == 0 &&
            base_sighash_type != <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_NONE">SIGHASH_NONE</a> &&
            base_sighash_type != <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_SINGLE">SIGHASH_SINGLE</a>
    ) {
        <b>let</b> <b>mut</b> all_sequences_concatenated = vector[];
        transaction.inputs().length().do!(|i| {
            all_sequences_concatenated.append(transaction.input_at(i).sequence());
        });
        hash256(all_sequences_concatenated)
    } <b>else</b> {
        <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_zerohash_32bytes">executor_utils::zerohash_32bytes</a>()
    };
    preimage.append(hash_sequence);
    // Serialize the TXID and VOUT <b>for</b> the <a href="../bitcoin_lib/input.md#bitcoin_lib_input">input</a> were signing
    <b>let</b> current_input = transaction.input_at(input_idx_to_sign);
    preimage.append(current_input.tx_id());
    preimage.append(current_input.vout());
    preimage.append(<a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_script_to_var_bytes">executor_utils::script_to_var_bytes</a>(input_script));
    preimage.append(amount_spent_by_this_input);
    preimage.append(current_input.sequence());
    // HASH256(concatenation of all (<a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>.value + <a href="../bitcoin_lib/output.md#bitcoin_lib_output">output</a>.script_pub_key_with_len))
    <b>let</b> hash_outputs: vector&lt;u8&gt; = <b>if</b> (
        base_sighash_type != <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_NONE">SIGHASH_NONE</a> && base_sighash_type != <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_SINGLE">SIGHASH_SINGLE</a>
    ) {
        <b>let</b> <b>mut</b> all_outputs_concat = vector[];
        transaction.outputs().length().do!(|i| {
            <b>let</b> output_ref = transaction.output_at(i);
            all_outputs_concat.append(output_ref.amount_bytes());
            all_outputs_concat.append(
                <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_script_to_var_bytes">executor_utils::script_to_var_bytes</a>(&output_ref.script_pubkey()),
            );
        });
        hash256(all_outputs_concat)
    } <b>else</b> <b>if</b> (
        base_sighash_type == <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_SIGHASH_SINGLE">SIGHASH_SINGLE</a> && input_idx_to_sign &lt; transaction.outputs().length()
    ) {
        <b>let</b> output_to_sign = transaction.output_at(input_idx_to_sign);
        <b>let</b> <b>mut</b> single_output_concatenated = vector[];
        single_output_concatenated.append(output_to_sign.amount_bytes());
        single_output_concatenated.append(
            <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_script_to_var_bytes">executor_utils::script_to_var_bytes</a>(&output_to_sign.script_pubkey()),
        );
        hash256(single_output_concatenated)
    } <b>else</b> {
        <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_zerohash_32bytes">executor_utils::zerohash_32bytes</a>()
    };
    preimage.append(hash_outputs);
    preimage.append(transaction.locktime());
    preimage.append(u32_to_le_bytes((sighash_type <b>as</b> u32)));
    preimage //Complete preimage data to be hashed (Once and later edcsa::verify will hash second time)
}
</code></pre>

</details>
