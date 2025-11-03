
<a name="bitcoin_lib_stack"></a>

# Module `bitcoin_lib::stack`



-  [Struct `Stack`](#bitcoin_lib_stack_Stack)
-  [Constants](#@Constants_0)
-  [Function `new`](#bitcoin_lib_stack_new)
-  [Function `new_with_data`](#bitcoin_lib_stack_new_with_data)
-  [Function `size`](#bitcoin_lib_stack_size)
-  [Function `is_empty`](#bitcoin_lib_stack_is_empty)
-  [Function `push`](#bitcoin_lib_stack_push)
-  [Function `push_byte`](#bitcoin_lib_stack_push_byte)
-  [Function `pop`](#bitcoin_lib_stack_pop)
-  [Function `top`](#bitcoin_lib_stack_top)


<pre><code><b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
</code></pre>



<a name="bitcoin_lib_stack_Stack"></a>

## Struct `Stack`



<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>internal: vector&lt;vector&lt;u8&gt;&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="bitcoin_lib_stack_MaximumStackSize"></a>



<pre><code><b>const</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_MaximumStackSize">MaximumStackSize</a>: u64 = 1000;
</code></pre>



<a name="bitcoin_lib_stack_MaximumElementSize"></a>



<pre><code><b>const</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_MaximumElementSize">MaximumElementSize</a>: u64 = 520;
</code></pre>



<a name="bitcoin_lib_stack_EReachMaximumSize"></a>



<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_EReachMaximumSize">EReachMaximumSize</a>: vector&lt;u8&gt; = b"Reach maximum element in <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack">stack</a>";
</code></pre>



<a name="bitcoin_lib_stack_EElementSizeInvalid"></a>



<pre><code>#[error]
<b>const</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_EElementSizeInvalid">EElementSizeInvalid</a>: vector&lt;u8&gt; = b"Element <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_size">size</a> is greater than 520";
</code></pre>



<a name="bitcoin_lib_stack_new"></a>

## Function `new`

creates stack


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_new">new</a>(): <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_new">new</a>(): <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a> {
    <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_new_with_data">new_with_data</a>(vector[])
}
</code></pre>



</details>

<a name="bitcoin_lib_stack_new_with_data"></a>

## Function `new_with_data`



<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_new_with_data">new_with_data</a>(data: vector&lt;vector&lt;u8&gt;&gt;): <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_new_with_data">new_with_data</a>(data: vector&lt;vector&lt;u8&gt;&gt;): <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a> {
    <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a> {
        internal: data,
    }
}
</code></pre>



</details>

<a name="bitcoin_lib_stack_size"></a>

## Function `size`

returns size of the stack


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_size">size</a>(s: &<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_size">size</a>(s: &<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a>): u64 {
    // u64 <b>for</b> type compatible
    s.internal.length()
}
</code></pre>



</details>

<a name="bitcoin_lib_stack_is_empty"></a>

## Function `is_empty`

checks if the stack is empty


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_is_empty">is_empty</a>(s: &<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_is_empty">is_empty</a>(s: &<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a>): bool {
    s.internal.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_is_empty">is_empty</a>()
}
</code></pre>



</details>

<a name="bitcoin_lib_stack_push"></a>

## Function `push`

pushes new element to the stack


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_push">push</a>(s: &<b>mut</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>, element: vector&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_push">push</a>(s: &<b>mut</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a>, element: vector&lt;u8&gt;) {
    <b>assert</b>!(s.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_size">size</a>() &lt; <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_MaximumStackSize">MaximumStackSize</a>, <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_EReachMaximumSize">EReachMaximumSize</a>);
    <b>assert</b>!(element.length() &lt;= <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_MaximumElementSize">MaximumElementSize</a>, <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_EElementSizeInvalid">EElementSizeInvalid</a>);
    s.internal.push_back(element);
}
</code></pre>



</details>

<a name="bitcoin_lib_stack_push_byte"></a>

## Function `push_byte`

pushes one byte to the stack


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_push_byte">push_byte</a>(s: &<b>mut</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>, byte: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_push_byte">push_byte</a>(s: &<b>mut</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a>, byte: u8) {
    <b>assert</b>!(s.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_size">size</a>() &lt; <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_MaximumStackSize">MaximumStackSize</a>, <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_EReachMaximumSize">EReachMaximumSize</a>);
    s.internal.push_back(vector[byte]);
}
</code></pre>



</details>

<a name="bitcoin_lib_stack_pop"></a>

## Function `pop`

Pop returns <code>option</code> top element of the stack and pop the top value


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_pop">pop</a>(s: &<b>mut</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>): <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;vector&lt;u8&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_pop">pop</a>(s: &<b>mut</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a>): option::Option&lt;vector&lt;u8&gt;&gt; {
    <b>if</b> (s.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_is_empty">is_empty</a>()) {
        option::none()
    } <b>else</b> {
        option::some(s.internal.pop_back())
    }
}
</code></pre>



</details>

<a name="bitcoin_lib_stack_top"></a>

## Function `top`

Top returns an <code>option</code> of the top element


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_top">top</a>(s: &<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">bitcoin_lib::stack::Stack</a>): <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;vector&lt;u8&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_top">top</a>(s: &<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_Stack">Stack</a>): option::Option&lt;vector&lt;u8&gt;&gt; {
    <b>if</b> (s.<a href="../bitcoin_lib/stack.md#bitcoin_lib_stack_is_empty">is_empty</a>()) {
        option::none()
    } <b>else</b> {
        option::some(s.internal[s.internal.length() - 1])
    }
}
</code></pre>



</details>
