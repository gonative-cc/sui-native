<a name="bitcoin_lib_interpreter"></a>

# Module `bitcoin_lib::interpreter`

- [Struct `EvalResult`](#bitcoin_lib_interpreter_EvalResult)
- [Struct `TransactionContext`](#bitcoin_lib_interpreter_TransactionContext)
- [Struct `Interpreter`](#bitcoin_lib_interpreter_Interpreter)
- [Constants](#@Constants_0)
- [Function `is_success`](#bitcoin_lib_interpreter_is_success)
- [Function `error`](#bitcoin_lib_interpreter_error)
- [Function `new_tx_context`](#bitcoin_lib_interpreter_new_tx_context)
- [Function `new_ip_with_context`](#bitcoin_lib_interpreter_new_ip_with_context)
- [Function `run`](#bitcoin_lib_interpreter_run)
- [Function `eval`](#bitcoin_lib_interpreter_eval)
- [Function `isInvalidOptCode`](#bitcoin_lib_interpreter_isInvalidOptCode)
- [Function `isBitcoinCoreInternalOpCode`](#bitcoin_lib_interpreter_isBitcoinCoreInternalOpCode)
- [Function `isSuccess`](#bitcoin_lib_interpreter_isSuccess)
- [Function `cast_to_bool`](#bitcoin_lib_interpreter_cast_to_bool)
- [Function `op_push_empty_vector`](#bitcoin_lib_interpreter_op_push_empty_vector)
- [Function `op_push_n_bytes`](#bitcoin_lib_interpreter_op_push_n_bytes)
- [Function `op_push_small_int`](#bitcoin_lib_interpreter_op_push_small_int)
- [Function `op_equal`](#bitcoin_lib_interpreter_op_equal)
- [Function `op_equal_verify`](#bitcoin_lib_interpreter_op_equal_verify)
- [Function `op_dup`](#bitcoin_lib_interpreter_op_dup)
- [Function `op_drop`](#bitcoin_lib_interpreter_op_drop)
- [Function `op_size`](#bitcoin_lib_interpreter_op_size)
- [Function `op_swap`](#bitcoin_lib_interpreter_op_swap)
- [Function `op_sha256`](#bitcoin_lib_interpreter_op_sha256)
- [Function `op_hash256`](#bitcoin_lib_interpreter_op_hash256)
- [Function `op_checksig`](#bitcoin_lib_interpreter_op_checksig)
- [Function `create_p2wpkh_scriptcode`](#bitcoin_lib_interpreter_create_p2wpkh_scriptcode)
- [Function `create_sighash`](#bitcoin_lib_interpreter_create_sighash)
- [Function `op_hash160`](#bitcoin_lib_interpreter_op_hash160)

<pre><code><b>use</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_btc_encoding">bitcoin_lib::btc_encoding</a>;
<b>use</b> <a href="../bitcoin_lib/crypto.md#bitcoin_lib_crypto">bitcoin_lib::crypto</a>;
<b>use</b> <a href="../bitcoin_lib/encoding.md#bitcoin_lib_encoding">bitcoin_lib::encoding</a>;
<b>use</b> <a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils">bitcoin_lib::executor_utils</a>;
<b>use</b> <a href="../bitcoin_lib/input.md#bitcoin_lib_input">bitcoin_lib::input</a>;
<b>use</b> <a href="../bitcoin_lib/output.md#bitcoin_lib_output">bitcoin_lib::output</a>;
<b>use</b> <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">bitcoin_lib::reader</a>;
<b>use</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160">bitcoin_lib::ripemd160</a>;
<b>use</b> <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash">bitcoin_lib::sighash</a>;
<b>use</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">bitcoin_lib::stack</a>;
<b>use</b> <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">bitcoin_lib::tx</a>;
<b>use</b> <a href="../bitcoin_lib/vector_utils.md#bitcoin_lib_vector_utils">bitcoin_lib::vector_utils</a>;
<b>use</b> <a href="../dependencies/std/hash.md#std_hash">std::hash</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../dependencies/sui/ecdsa_k1.md#sui_ecdsa_k1">sui::ecdsa_k1</a>;
</code></pre>

<a name="bitcoin_lib_interpreter_EvalResult"></a>

## Struct `EvalResult`

<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">EvalResult</a> <b>has</b> <b>copy</b>, drop
</code></pre>

<details>
<summary>Fields</summary>

<dl>
<dt>
<code>res: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>err: u64</code>
</dt>
<dd>
</dd>
</dl>

</details>

<a name="bitcoin_lib_interpreter_TransactionContext"></a>

## Struct `TransactionContext`

<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_TransactionContext">TransactionContext</a> <b>has</b> <b>copy</b>, drop
</code></pre>

<details>
<summary>Fields</summary>

<dl>
<dt>
<code><a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a></code>
</dt>
<dd>
</dd>
<dt>
<code>input_index: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>sig_version: u8</code>
</dt>
<dd>
</dd>
</dl>

</details>

<a name="bitcoin_lib_interpreter_Interpreter"></a>

## Struct `Interpreter`

<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a> <b>has</b> <b>copy</b>, drop
</code></pre>

<details>
<summary>Fields</summary>

<dl>
<dt>
<code><a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>: <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">reader</a>: <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader_Reader">bitcoin_lib::reader::Reader</a></code>
</dt>
<dd>
</dd>
<dt>
<code>tx_context: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_TransactionContext">bitcoin_lib::interpreter::TransactionContext</a>&gt;</code>
</dt>
<dd>
</dd>
</dl>

</details>

<a name="@Constants_0"></a>

## Constants

<a name="bitcoin_lib_interpreter_OP_0"></a>

These constants are the values of the official opcodes used on the btc wiki,
in bitcoin core and in most if not all other references and software related
to handling BTC scripts.
https://github.com/btcsuite/btcd/blob/master/txscript/opcode.go

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_0">OP_0</a>: u8 = 0;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_PUSHBYTES_1"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUSHBYTES_1">OP_PUSHBYTES_1</a>: u8 = 1;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_PUSHBYTES_20"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUSHBYTES_20">OP_PUSHBYTES_20</a>: u8 = 20;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_PUSHBYTES_75"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUSHBYTES_75">OP_PUSHBYTES_75</a>: u8 = 75;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_1"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_1">OP_1</a>: u8 = 81;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_16"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_16">OP_16</a>: u8 = 96;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_DROP"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_DROP">OP_DROP</a>: u8 = 117;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_DUP"></a>

Duplicate the top item on the stack.

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_DUP">OP_DUP</a>: u8 = 118;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_SWAP"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_SWAP">OP_SWAP</a>: u8 = 124;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_SIZE"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_SIZE">OP_SIZE</a>: u8 = 130;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_EQUAL"></a>

Compare the top two items on the stack and push 1 if they are equal, 0 otherwise.

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_EQUAL">OP_EQUAL</a>: u8 = 135;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_EQUALVERIFY"></a>

Compare the top two items on the stack and halts the script if they are not equal.

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_EQUALVERIFY">OP_EQUALVERIFY</a>: u8 = 136;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_SHA256"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_SHA256">OP_SHA256</a>: u8 = 168;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_HASH160"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_HASH160">OP_HASH160</a>: u8 = 169;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_HASH256"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_HASH256">OP_HASH256</a>: u8 = 170;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_CHECKSIG"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_CHECKSIG">OP_CHECKSIG</a>: u8 = 172;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_UNKNOWN187"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_UNKNOWN187">OP_UNKNOWN187</a>: u8 = 187;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_UNKNOWN249"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_UNKNOWN249">OP_UNKNOWN249</a>: u8 = 249;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_SMALLINTEGER"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_SMALLINTEGER">OP_SMALLINTEGER</a>: u8 = 250;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_PUBKEYS"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUBKEYS">OP_PUBKEYS</a>: u8 = 251;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_UNKNOWN252"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_UNKNOWN252">OP_UNKNOWN252</a>: u8 = 252;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_PUBKEYHASH"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUBKEYHASH">OP_PUBKEYHASH</a>: u8 = 253;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_PUBKEY"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUBKEY">OP_PUBKEY</a>: u8 = 254;
</code></pre>

<a name="bitcoin_lib_interpreter_OP_INVALIDOPCODE"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_INVALIDOPCODE">OP_INVALIDOPCODE</a>: u8 = 255;
</code></pre>

<a name="bitcoin_lib_interpreter_SIG_VERSION_BASE"></a>

Signature types

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SIG_VERSION_BASE">SIG_VERSION_BASE</a>: u8 = 0;
</code></pre>

<a name="bitcoin_lib_interpreter_SIG_VERSION_WITNESS_V0"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SIG_VERSION_WITNESS_V0">SIG_VERSION_WITNESS_V0</a>: u8 = 1;
</code></pre>

<a name="bitcoin_lib_interpreter_SHA256"></a>

Hash types

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SHA256">SHA256</a>: u8 = 1;
</code></pre>

<a name="bitcoin_lib_interpreter_SUCCESS"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>: u64 = 0;
</code></pre>

<a name="bitcoin_lib_interpreter_EEqualVerify"></a>

<pre><code>#[<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_error">error</a>]
<b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EEqualVerify">EEqualVerify</a>: vector&lt;u8&gt; = b"SCRIPT_ERR_EQUALVERIFY";
</code></pre>

<a name="bitcoin_lib_interpreter_EUnsupportedSigVersionForChecksig"></a>

<pre><code>#[<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_error">error</a>]
<b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EUnsupportedSigVersionForChecksig">EUnsupportedSigVersionForChecksig</a>: vector&lt;u8&gt; = b"Unsupported signature version <b>for</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_checksig">op_checksig</a>";
</code></pre>

<a name="bitcoin_lib_interpreter_EInvalidPKHLength"></a>

<pre><code>#[<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_error">error</a>]
<b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EInvalidPKHLength">EInvalidPKHLength</a>: vector&lt;u8&gt; = b"PHK length must be 20";
</code></pre>

<a name="bitcoin_lib_interpreter_EPopStackEmpty"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>: u64 = 1;
</code></pre>

<a name="bitcoin_lib_interpreter_ETopStackEmpty"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_ETopStackEmpty">ETopStackEmpty</a>: u64 = 2;
</code></pre>

<a name="bitcoin_lib_interpreter_EMissingTxCtx"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EMissingTxCtx">EMissingTxCtx</a>: u64 = 3;
</code></pre>

<a name="bitcoin_lib_interpreter_EInvalidOpcode"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EInvalidOpcode">EInvalidOpcode</a>: u64 = 4;
</code></pre>

<a name="bitcoin_lib_interpreter_EInternalBitcoinCoreOpcode"></a>

<pre><code><b>const</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EInternalBitcoinCoreOpcode">EInternalBitcoinCoreOpcode</a>: u64 = 5;
</code></pre>

<a name="bitcoin_lib_interpreter_is_success"></a>

## Function `is_success`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_is_success">is_success</a>(res: &<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">bitcoin_lib::interpreter::EvalResult</a>): bool
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_is_success">is_success</a>(res: &<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">EvalResult</a>): bool {
    <b>return</b> res.err == 0 && res.res
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_error"></a>

## Function `error`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_error">error</a>(res: &<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">bitcoin_lib::interpreter::EvalResult</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_error">error</a>(res: &<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">EvalResult</a>): u64 {
    res.err
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_new_tx_context"></a>

## Function `new_tx_context`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_new_tx_context">new_tx_context</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>, input_index: u64, amount: u64, sig_version: u8): <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_TransactionContext">bitcoin_lib::interpreter::TransactionContext</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_new_tx_context">new_tx_context</a>(
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: Transaction,
    input_index: u64,
    amount: u64,
    sig_version: u8,
): <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_TransactionContext">TransactionContext</a> {
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_TransactionContext">TransactionContext</a> {
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>,
        input_index,
        amount,
        sig_version,
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_new_ip_with_context"></a>

## Function `new_ip_with_context`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_new_ip_with_context">new_ip_with_context</a>(<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>: <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>, tx_ctx: <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_TransactionContext">bitcoin_lib::interpreter::TransactionContext</a>): <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_new_ip_with_context">new_ip_with_context</a>(<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>: Stack, tx_ctx: <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_TransactionContext">TransactionContext</a>): <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a> {
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a> {
        <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>: <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>,
        <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">reader</a>: <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader_new">reader::new</a>(vector[]),
        tx_context: option::some(tx_ctx),
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_run"></a>

## Function `run`

Execute btc script

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_run">run</a>(<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx_Transaction">bitcoin_lib::tx::Transaction</a>, <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>: <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>, script: vector&lt;u8&gt;, input_idx: u64, amount: u64): <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">bitcoin_lib::interpreter::EvalResult</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_run">run</a>(
    <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>: Transaction,
    <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>: Stack,
    script: vector&lt;u8&gt;,
    input_idx: u64,
    amount: u64,
): <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">EvalResult</a> {
    <b>let</b> sig_version = <b>if</b> (<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>.is_witness()) {
        <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SIG_VERSION_WITNESS_V0">SIG_VERSION_WITNESS_V0</a>
    } <b>else</b> {
        <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SIG_VERSION_BASE">SIG_VERSION_BASE</a>
    };
    <b>let</b> ctx = <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_new_tx_context">new_tx_context</a>(
        <a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>,
        input_idx <b>as</b> u64,
        amount,
        sig_version,
    );
    <b>let</b> <b>mut</b> ip = <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_new_ip_with_context">new_ip_with_context</a>(<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>, ctx);
    <b>let</b> r = <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader_new">reader::new</a>(script);
    ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_eval">eval</a>(r)
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_eval"></a>

## Function `eval`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_eval">eval</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>, r: <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader_Reader">bitcoin_lib::reader::Reader</a>): <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">bitcoin_lib::interpreter::EvalResult</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_eval">eval</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>, r: Reader): <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">EvalResult</a> {
    ip.<a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">reader</a> = r; // init new  <a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">reader</a>
    <b>while</b> (!ip.<a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">reader</a>.end_stream()) {
        <b>let</b> op = ip.<a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">reader</a>.next_opcode();
        <b>let</b> err = <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_0">OP_0</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_empty_vector">op_push_empty_vector</a>()
        } <b>else</b> <b>if</b> (op &gt;= <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUSHBYTES_1">OP_PUSHBYTES_1</a> && op &lt;= <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUSHBYTES_75">OP_PUSHBYTES_75</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_n_bytes">op_push_n_bytes</a>(op)
        } <b>else</b> <b>if</b> (op &gt;= <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_1">OP_1</a> && op &lt;= <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_16">OP_16</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_small_int">op_push_small_int</a>(op)
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_DUP">OP_DUP</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_dup">op_dup</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_DROP">OP_DROP</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_drop">op_drop</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_SWAP">OP_SWAP</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_swap">op_swap</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_SIZE">OP_SIZE</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_size">op_size</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_EQUAL">OP_EQUAL</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_equal">op_equal</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_EQUALVERIFY">OP_EQUALVERIFY</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_equal_verify">op_equal_verify</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_SHA256">OP_SHA256</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_sha256">op_sha256</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_HASH256">OP_HASH256</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_hash256">op_hash256</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_CHECKSIG">OP_CHECKSIG</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_checksig">op_checksig</a>()
        } <b>else</b> <b>if</b> (op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_HASH160">OP_HASH160</a>) {
            ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_hash160">op_hash160</a>()
        } <b>else</b> <b>if</b> (<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isBitcoinCoreInternalOpCode">isBitcoinCoreInternalOpCode</a>(op)) {
            // Bitcoin Core internal <b>use</b> opcode.  Defined here <b>for</b> completeness.
            // https://github.com/btcsuite/btcd/blob/v0.24.2/txscript/opcode.go#L581
            <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EInternalBitcoinCoreOpcode">EInternalBitcoinCoreOpcode</a>
        } <b>else</b> {
            // <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isInvalidOptCode">isInvalidOptCode</a>
            <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EInvalidOpcode">EInvalidOpcode</a>
        };
        <b>if</b> (err != 0) {
            <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">EvalResult</a> {
                res: <b>false</b>,
                err,
            }
        };
    };
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EvalResult">EvalResult</a> {
        res: ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isSuccess">isSuccess</a>(),
        err: 0,
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_isInvalidOptCode"></a>

## Function `isInvalidOptCode`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isInvalidOptCode">isInvalidOptCode</a>(op: u8): bool
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isInvalidOptCode">isInvalidOptCode</a>(op: u8): bool {
    op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_INVALIDOPCODE">OP_INVALIDOPCODE</a> ||
        op &gt;= <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_UNKNOWN187">OP_UNKNOWN187</a> && op &lt;= <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_UNKNOWN249">OP_UNKNOWN249</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_isBitcoinCoreInternalOpCode"></a>

## Function `isBitcoinCoreInternalOpCode`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isBitcoinCoreInternalOpCode">isBitcoinCoreInternalOpCode</a>(op: u8): bool
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isBitcoinCoreInternalOpCode">isBitcoinCoreInternalOpCode</a>(op: u8): bool {
    op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_UNKNOWN252">OP_UNKNOWN252</a> || op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_SMALLINTEGER">OP_SMALLINTEGER</a> ||
        op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUBKEY">OP_PUBKEY</a> || op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUBKEYS">OP_PUBKEYS</a> || op == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUBKEYHASH">OP_PUBKEYHASH</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_isSuccess"></a>

## Function `isSuccess`

check evaluate is valid
evaluation valid if the stack not empty
and top element is non zero value

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isSuccess">isSuccess</a>(ip: &<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): bool
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_isSuccess">isSuccess</a>(ip: &<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): bool {
    <b>if</b> (ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.is_empty()) {
        <b>return</b> <b>false</b>
    };
    <b>let</b> top = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.top();
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_cast_to_bool">cast_to_bool</a>(&top.destroy_or!(<b>abort</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_ETopStackEmpty">ETopStackEmpty</a>))
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_cast_to_bool"></a>

## Function `cast_to_bool`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_cast_to_bool">cast_to_bool</a>(v: &vector&lt;u8&gt;): bool
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_cast_to_bool">cast_to_bool</a>(v: &vector&lt;u8&gt;): bool {
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; v.length()) {
        <b>if</b> (v[i] != 0) {
            // Can be negative zero
            <b>if</b> (i == v.length()-1 && v[i] == 0x80) <b>return</b> <b>false</b>;
            <b>return</b> <b>true</b>;
        };
        i = i + 1;
    };
    <b>false</b>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_push_empty_vector"></a>

## Function `op_push_empty_vector`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_empty_vector">op_push_empty_vector</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_empty_vector">op_push_empty_vector</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(vector[]);
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_push_n_bytes"></a>

## Function `op_push_n_bytes`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_n_bytes">op_push_n_bytes</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>, num_bytes_to_push: u8): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_n_bytes">op_push_n_bytes</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>, num_bytes_to_push: u8): u64 {
    <b>let</b> data_to_push = ip.<a href="../bitcoin_lib/reader.md#bitcoin_lib_reader">reader</a>.read(num_bytes_to_push <b>as</b> u64);
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(data_to_push);
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_push_small_int"></a>

## Function `op_push_small_int`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_small_int">op_push_small_int</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>, opcode: u8): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_push_small_int">op_push_small_int</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>, opcode: u8): u64 {
    // <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_1">OP_1</a> (81) corresponds to 1  (81 - 81 + 1 = 1)
    // <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_16">OP_16</a> (96) corresponds to 16 (96 - 81 + 1 = 16)
    <b>let</b> numeric_value: u8 = opcode - <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_1">OP_1</a> + 1;
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push_byte(numeric_value);
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_equal"></a>

## Function `op_equal`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_equal">op_equal</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_equal">op_equal</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> first_value = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <b>let</b> second_value = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <b>if</b> (first_value.is_none() || second_value.is_none()) {
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>
    };
    <b>let</b> ans = <b>if</b> (first_value == second_value) {
        vector[1]
    } <b>else</b> {
        vector[0]
    };
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(ans);
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_equal_verify"></a>

## Function `op_equal_verify`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_equal_verify">op_equal_verify</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_equal_verify">op_equal_verify</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> previous_opcode_result = ip.<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_equal">op_equal</a>();
    <b>if</b> (previous_opcode_result != <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>) {
        <b>return</b> previous_opcode_result
    };
    <b>let</b> is_equal = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop().destroy_or!(<b>abort</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>);
    <b>assert</b>!(is_equal == vector[1], <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EEqualVerify">EEqualVerify</a>);
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_dup"></a>

## Function `op_dup`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_dup">op_dup</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_dup">op_dup</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> <b>mut</b> value = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.top();
    <b>if</b> (value.is_none()) {
        <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>
    } <b>else</b> {
        ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(value.extract());
        <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_drop"></a>

## Function `op_drop`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_drop">op_drop</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_drop">op_drop</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>if</b> (ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.is_empty()) {
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>
    };
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_size"></a>

## Function `op_size`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_size">op_size</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_size">op_size</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> <b>mut</b> top_element = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.top();
    <b>if</b> (top_element.is_none()) {
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_ETopStackEmpty">ETopStackEmpty</a>
    };
    <b>let</b> size = top_element.extract().length();
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(<a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_u64_to_cscriptnum">executor_utils::u64_to_cscriptnum</a>(size));
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_swap"></a>

## Function `op_swap`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_swap">op_swap</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_swap">op_swap</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> <b>mut</b> first_element = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <b>let</b> <b>mut</b> second_element = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <b>if</b> (first_element.is_none() || second_element.is_none()) {
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>
    };
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(first_element.extract());
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(second_element.extract());
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_sha256"></a>

## Function `op_sha256`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_sha256">op_sha256</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_sha256">op_sha256</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> <b>mut</b> value = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <b>if</b> (value.is_none()) {
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>
    };
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(sha2_256(value.extract()));
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_hash256"></a>

## Function `op_hash256`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_hash256">op_hash256</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_hash256">op_hash256</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> <b>mut</b> value = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <b>if</b> (value.is_none()) {
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>
    };
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(hash256(value.extract()));
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_checksig"></a>

## Function `op_checksig`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_checksig">op_checksig</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_checksig">op_checksig</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> <b>mut</b> pubkey_bytes = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <b>if</b> (pubkey_bytes.is_none()) {
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>
    };
    <b>let</b> <b>mut</b> sig_bytes = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop();
    <b>if</b> (sig_bytes.is_none()) {
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>
    };
    <b>let</b> pubkey_bytes = pubkey_bytes.extract();
    <b>let</b> <b>mut</b> sig_bytes = sig_bytes.extract();
    <b>if</b> (sig_bytes.is_empty()) {
        ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(<a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_vector_false">executor_utils::vector_false</a>());
        <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
    };
    // https://learnmeabitcoin.com/technical/keys/signature/
    <b>let</b> (sig_to_verify, sighash_flag) = <a href="../bitcoin_lib/encoding.md#bitcoin_lib_btc_encoding_parse_btc_sig">btc_encoding::parse_btc_sig</a>(&<b>mut</b> sig_bytes);
    <b>if</b> (option::is_none(&ip.tx_context)) { <b>return</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EMissingTxCtx">EMissingTxCtx</a> };
    <b>let</b> message_digest = <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_create_sighash">create_sighash</a>(ip, pubkey_bytes, sighash_flag);
    <b>let</b> signature_is_valid = <a href="../dependencies/sui/ecdsa_k1.md#sui_ecdsa_k1_secp256k1_verify">sui::ecdsa_k1::secp256k1_verify</a>(
        &sig_to_verify,
        &pubkey_bytes,
        &message_digest,
        <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SHA256">SHA256</a>,
    );
    <b>if</b> (signature_is_valid) {
        ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(<a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_vector_true">executor_utils::vector_true</a>());
    } <b>else</b> {
        ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(<a href="../bitcoin_lib/utils.md#bitcoin_lib_executor_utils_vector_false">executor_utils::vector_false</a>());
    };
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_create_p2wpkh_scriptcode"></a>

## Function `create_p2wpkh_scriptcode`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_create_p2wpkh_scriptcode">create_p2wpkh_scriptcode</a>(pkh: vector&lt;u8&gt;): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_create_p2wpkh_scriptcode">create_p2wpkh_scriptcode</a>(pkh: vector&lt;u8&gt;): vector&lt;u8&gt; {
    <b>assert</b>!(pkh.length() == 20, <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EInvalidPKHLength">EInvalidPKHLength</a>);
    <b>let</b> <b>mut</b> script = vector::empty&lt;u8&gt;();
    script.push_back(<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_DUP">OP_DUP</a>);
    script.push_back(<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_HASH160">OP_HASH160</a>);
    script.push_back(<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_PUSHBYTES_20">OP_PUSHBYTES_20</a>);
    script.append(pkh);
    script.push_back(<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_EQUALVERIFY">OP_EQUALVERIFY</a>);
    script.push_back(<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_OP_CHECKSIG">OP_CHECKSIG</a>);
    script
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_create_sighash"></a>

## Function `create_sighash`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_create_sighash">create_sighash</a>(ip: &<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>, pub_key: vector&lt;u8&gt;, sighash_flag: u8): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_create_sighash">create_sighash</a>(ip: &<a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>, pub_key: vector&lt;u8&gt;, sighash_flag: u8): vector&lt;u8&gt; {
    <b>let</b> ctx = ip.tx_context.borrow();
    <b>if</b> (ctx.sig_version == <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SIG_VERSION_WITNESS_V0">SIG_VERSION_WITNESS_V0</a>) {
        <b>let</b> sha = sha2_256(pub_key);
        <b>let</b> <b>mut</b> hash160 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_new">ripemd160::new</a>();
        hash160.write(sha, sha.length());
        <b>let</b> pkh = hash160.finalize();
        <b>let</b> script_code_to_use_for_sighash = <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_create_p2wpkh_scriptcode">create_p2wpkh_scriptcode</a>(pkh);
        <b>let</b> bip143_preimage = <a href="../bitcoin_lib/sighash.md#bitcoin_lib_sighash_create_segwit_preimage">sighash::create_segwit_preimage</a>(
            &ctx.<a href="../bitcoin_lib/tx.md#bitcoin_lib_tx">tx</a>,
            ctx.input_index,
            &script_code_to_use_for_sighash,
            u64_to_le_bytes(ctx.amount),
            sighash_flag,
        );
        // <a href="../dependencies/sui/ecdsa_k1.md#sui_ecdsa_k1_secp256k1_verify">sui::ecdsa_k1::secp256k1_verify</a> does the 2nd hash. We need to do the first here
        sha2_256(bip143_preimage)
    } <b>else</b> {
        <b>abort</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EUnsupportedSigVersionForChecksig">EUnsupportedSigVersionForChecksig</a>
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_interpreter_op_hash160"></a>

## Function `op_hash160`

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_hash160">op_hash160</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">bitcoin_lib::interpreter::Interpreter</a>): u64
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_op_hash160">op_hash160</a>(ip: &<b>mut</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_Interpreter">Interpreter</a>): u64 {
    <b>let</b> value = ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.pop().destroy_or!(<b>abort</b> <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_EPopStackEmpty">EPopStackEmpty</a>);
    <b>let</b> sha = sha2_256(value);
    <b>let</b> <b>mut</b> hasher = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_new">ripemd160::new</a>();
    hasher.write(sha, sha.length());
    ip.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>.push(hasher.finalize());
    <a href="../bitcoin_lib/interpreter.md#bitcoin_lib_interpreter_SUCCESS">SUCCESS</a>
}
</code></pre>

</details>
