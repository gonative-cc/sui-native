<a name="bitcoin_lib_ripemd160"></a>

# Module `bitcoin_lib::ripemd160`

- [Struct `Ripemd160`](#bitcoin_lib_ripemd160_Ripemd160)
- [Function `new`](#bitcoin_lib_ripemd160_new)
- [Function `bitnot`](#bitcoin_lib_ripemd160_bitnot)
- [Function `f1`](#bitcoin_lib_ripemd160_f1)
- [Function `f2`](#bitcoin_lib_ripemd160_f2)
- [Function `f3`](#bitcoin_lib_ripemd160_f3)
- [Function `f4`](#bitcoin_lib_ripemd160_f4)
- [Function `f5`](#bitcoin_lib_ripemd160_f5)
- [Function `rol`](#bitcoin_lib_ripemd160_rol)
- [Function `Round`](#bitcoin_lib_ripemd160_Round)
- [Function `R11`](#bitcoin_lib_ripemd160_R11)
- [Function `R21`](#bitcoin_lib_ripemd160_R21)
- [Function `R31`](#bitcoin_lib_ripemd160_R31)
- [Function `R41`](#bitcoin_lib_ripemd160_R41)
- [Function `R51`](#bitcoin_lib_ripemd160_R51)
- [Function `R12`](#bitcoin_lib_ripemd160_R12)
- [Function `R22`](#bitcoin_lib_ripemd160_R22)
- [Function `R32`](#bitcoin_lib_ripemd160_R32)
- [Function `R42`](#bitcoin_lib_ripemd160_R42)
- [Function `R52`](#bitcoin_lib_ripemd160_R52)
- [Function `transform`](#bitcoin_lib_ripemd160_transform)
- [Function `write`](#bitcoin_lib_ripemd160_write)
- [Function `finalize`](#bitcoin_lib_ripemd160_finalize)
- [Function `veccopy`](#bitcoin_lib_ripemd160_veccopy)
- [Function `writeLE64`](#bitcoin_lib_ripemd160_writeLE64)
- [Function `writeLE32`](#bitcoin_lib_ripemd160_writeLE32)
- [Function `readLE32`](#bitcoin_lib_ripemd160_readLE32)

<pre><code></code></pre>

<a name="bitcoin_lib_ripemd160_Ripemd160"></a>

## Struct `Ripemd160`

<pre><code><b>public</b> <b>struct</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Ripemd160">Ripemd160</a> <b>has</b> <b>copy</b>, drop
</code></pre>

<details>
<summary>Fields</summary>

<dl>
<dt>
<code>s: vector&lt;u32&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>buf: vector&lt;u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>bytes: u64</code>
</dt>
<dd>
</dd>
</dl>

</details>

<a name="bitcoin_lib_ripemd160_new"></a>

## Function `new`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_new">new</a>(): <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Ripemd160">bitcoin_lib::ripemd160::Ripemd160</a>
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_new">new</a>(): <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Ripemd160">Ripemd160</a> {
    <b>let</b> s = vector[0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0];
    <b>let</b> <b>mut</b> buf = vector[];
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; 64) {
        buf.push_back(0);
        i = i + 1;
    };
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Ripemd160">Ripemd160</a> {
        s: s,
        buf: buf,
        bytes: 0,
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_bitnot"></a>

## Function `bitnot`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_bitnot">bitnot</a>(x: u32): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_bitnot">bitnot</a>(x: u32): u32 {
    0xffffffff - x
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_f1"></a>

## Function `f1`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f1">f1</a>(x: u32, y: u32, z: u32): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f1">f1</a>(x: u32, y: u32, z: u32): u32 {
    x^y^z
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_f2"></a>

## Function `f2`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f2">f2</a>(x: u32, y: u32, z: u32): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f2">f2</a>(x: u32, y: u32, z: u32): u32 {
    (x & y) | (<a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_bitnot">bitnot</a>(x) & z)
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_f3"></a>

## Function `f3`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f3">f3</a>(x: u32, y: u32, z: u32): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f3">f3</a>(x: u32, y: u32, z: u32): u32 {
    (x | <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_bitnot">bitnot</a>(y)) ^ z
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_f4"></a>

## Function `f4`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f4">f4</a>(x: u32, y: u32, z: u32): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f4">f4</a>(x: u32, y: u32, z: u32): u32 {
    (x & z) |(y & <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_bitnot">bitnot</a>(z))
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_f5"></a>

## Function `f5`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f5">f5</a>(x: u32, y: u32, z: u32): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f5">f5</a>(x: u32, y: u32, z: u32): u32 {
    x ^(y | <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_bitnot">bitnot</a>(z))
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_rol"></a>

## Function `rol`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_rol">rol</a>(x: u32, i: u8): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_rol">rol</a>(x: u32, i: u8): u32 {
    <b>return</b> (x &lt;&lt; i) | (x &gt;&gt; (32 - i))
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_Round"></a>

## Function `Round`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, f: u32, x: u32, k: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, f: u32, x: u32, k: u32, r: u8) {
    <b>let</b> m = 0xffffffff;
    <b>let</b> <b>mut</b> tmp = *a <b>as</b> u64;
    tmp = (tmp + (f <b>as</b> u64)) & m;
    tmp = (tmp + (x <b>as</b> u64)) & m;
    tmp = (tmp + (k <b>as</b> u64)) & m;
    *a = (((<a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_rol">rol</a>(tmp <b>as</b> u32, r) <b>as</b> u64) + (e <b>as</b> u64)) & m) <b>as</b> u32;
    *c = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_rol">rol</a>(*c, 10);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R11"></a>

## Function `R11`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f1">f1</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R21"></a>

## Function `R21`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f2">f2</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0x5A827999, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R31"></a>

## Function `R31`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f3">f3</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0x6ED9EBA1, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R41"></a>

## Function `R41`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f4">f4</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0x8F1BBCDC, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R51"></a>

## Function `R51`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f5">f5</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0xA953FD4E, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R12"></a>

## Function `R12`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f5">f5</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0x50A28BE6, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R22"></a>

## Function `R22`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f4">f4</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0x5C4DD124, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R32"></a>

## Function `R32`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f3">f3</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0x6D703EF3, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R42"></a>

## Function `R42`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f2">f2</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0x7A6D76E9, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_R52"></a>

## Function `R52`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(a: &<b>mut</b> u32, b: u32, c: &<b>mut</b> u32, d: u32, e: u32, x: u32, r: u8) {
    <b>let</b> t = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_f1">f1</a>(b, *c, d);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Round">Round</a>(a, b, c, d, e, t, x, 0, r);
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_transform"></a>

## Function `transform`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_transform">transform</a>(s: &<b>mut</b> vector&lt;u32&gt;, chunk: vector&lt;u8&gt;)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_transform">transform</a>(s: &<b>mut</b> vector&lt;u32&gt;, chunk: vector&lt;u8&gt;) {
    <b>let</b> <b>mut</b> a1 = s[0];
    <b>let</b> <b>mut</b> b1 = s[1];
    <b>let</b> <b>mut</b> c1 = s[2];
    <b>let</b> <b>mut</b> d1 = s[3];
    <b>let</b> <b>mut</b> e1 = s[4];
    <b>let</b> <b>mut</b> a2 = a1;
    <b>let</b> <b>mut</b> b2 = b1;
    <b>let</b> <b>mut</b> c2 = c1;
    <b>let</b> <b>mut</b> d2 = d1;
    <b>let</b> <b>mut</b> e2 = e1;
    <b>let</b> w0 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 0);
    <b>let</b> w1 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 4);
    <b>let</b> w2 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 8);
    <b>let</b> w3 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 12);
    <b>let</b> w4 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 16);
    <b>let</b> w5 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 20);
    <b>let</b> w6 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 24);
    <b>let</b> w7 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 28);
    <b>let</b> w8 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 32);
    <b>let</b> w9 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 36);
    <b>let</b> w10 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 40);
    <b>let</b> w11 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 44);
    <b>let</b> w12 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 48);
    <b>let</b> w13 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 52);
    <b>let</b> w14 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 56);
    <b>let</b> w15 = <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(&chunk, 60);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w0, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w5, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w1, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w14, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w2, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w7, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w3, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w0, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w4, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w9, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w5, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w2, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w6, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w11, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w7, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w4, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w8, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w13, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w9, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w6, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w10, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w15, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w11, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w8, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w12, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w1, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w13, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w10, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w14, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w3, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R11">R11</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w15, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R12">R12</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w12, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w7, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w6, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w4, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w11, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w13, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w3, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w1, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w7, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w10, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w0, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w6, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w13, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w15, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w5, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w3, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w10, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w12, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w14, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w0, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w15, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w9, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w8, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w5, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w12, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w2, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w4, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w14, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w9, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w11, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w1, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R21">R21</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w8, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R22">R22</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w2, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w3, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w15, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w10, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w5, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w14, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w1, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w4, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w3, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w9, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w7, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w15, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w14, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w8, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w6, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w1, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w9, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w2, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w11, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w7, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w8, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w0, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w12, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w6, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w2, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w13, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w10, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w11, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w0, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w5, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w4, 7);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R31">R31</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w12, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R32">R32</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w13, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w1, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w8, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w9, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w6, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w11, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w4, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w10, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w1, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w0, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w3, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w8, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w11, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w12, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w15, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w4, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w0, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w13, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w5, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w3, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w12, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w7, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w2, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w15, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w13, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w14, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w9, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w5, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w7, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w6, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w10, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R41">R41</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w2, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R42">R42</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w14, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w4, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w12, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w0, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w15, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w5, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w10, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w9, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w4, 9);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w7, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w1, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w12, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w5, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w2, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w8, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w10, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w7, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w14, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w6, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w1, 12);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w2, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w3, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w13, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> a1, b1, &<b>mut</b> c1, d1, e1, w8, 14);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> a2, b2, &<b>mut</b> c2, d2, e2, w14, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> e1, a1, &<b>mut</b> b1, c1, d1, w11, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> e2, a2, &<b>mut</b> b2, c2, d2, w0, 15);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> d1, e1, &<b>mut</b> a1, b1, c1, w6, 8);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> d2, e2, &<b>mut</b> a2, b2, c2, w3, 13);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> c1, d1, &<b>mut</b> e1, a1, b1, w15, 5);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> c2, d2, &<b>mut</b> e2, a2, b2, w9, 11);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R51">R51</a>(&<b>mut</b> b1, c1, &<b>mut</b> d1, e1, a1, w13, 6);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_R52">R52</a>(&<b>mut</b> b2, c2, &<b>mut</b> d2, e2, a2, w11, 11);
    <b>let</b> t = s[0];
    <b>let</b> s1 = s[1];
    <b>let</b> s2 = s[2];
    <b>let</b> s3 = s[3];
    <b>let</b> s4 = s[4];
    <b>let</b> m = 0xffffffff;
    <b>let</b> b = s.borrow_mut(0);
    *b = (((s1 <b>as</b> u64)  + (c1 <b>as</b> u64) + (d2 <b>as</b> u64)) & m) <b>as</b> u32;
    <b>let</b> b = s.borrow_mut(1);
    *b = (((s2 <b>as</b> u64)  + (d1 <b>as</b> u64) + (e2 <b>as</b> u64)) & m) <b>as</b> u32;
    // *b = s2 + d1 + e2;
    <b>let</b> b = s.borrow_mut(2);
    *b = (((s3 <b>as</b> u64)  + (e1 <b>as</b> u64) + (a2 <b>as</b> u64)) & m) <b>as</b> u32;
    // *b = s3 + e1 + a2;
    <b>let</b> b = s.borrow_mut(3);
    *b = (((s4 <b>as</b> u64)  + (a1 <b>as</b> u64) + (b2 <b>as</b> u64)) & m) <b>as</b> u32;
    // *b = s4 + a1 + b2;
    <b>let</b> b = s.borrow_mut(4);
    *b = (((t <b>as</b> u64)  + (b1 <b>as</b> u64) + (c2 <b>as</b> u64)) & m) <b>as</b> u32;
    // *b = t + b1 + c2;
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_write"></a>

## Function `write`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_write">write</a>(h: &<b>mut</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Ripemd160">bitcoin_lib::ripemd160::Ripemd160</a>, data: vector&lt;u8&gt;, len: u64)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_write">write</a>(h: &<b>mut</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Ripemd160">Ripemd160</a>, data: vector&lt;u8&gt;, len: u64) {
    <b>let</b> end = len;
    <b>let</b> <b>mut</b> data_index = 0;
    <b>let</b> <b>mut</b> bufsize = h.bytes % 64;
    <b>if</b> (bufsize &gt; 0 && bufsize + len &gt;= 64) {
        <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_veccopy">veccopy</a>(&<b>mut</b> h.buf, bufsize, data, data_index, 64 - bufsize);
        h.bytes = h.bytes + 64 - bufsize;
        data_index = data_index + 64 - bufsize;
        <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_transform">transform</a>(&<b>mut</b> h.s, h.buf);
        bufsize = 0;
    };
    <b>while</b> (end - data_index &gt;= 64) {
        <b>let</b> <b>mut</b> v: vector&lt;u8&gt; = vector[];
        do!(64, |i| v.push_back(data[i + data_index]));
        <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_transform">transform</a>(&<b>mut</b> h.s, v);
        h.bytes = h.bytes + 64;
        data_index = data_index + 64;
    };
    <b>if</b> (end &gt; data_index) {
        <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_veccopy">veccopy</a>(&<b>mut</b> h.buf, bufsize, data, data_index, end-data_index);
        h.bytes = h.bytes + end - data_index;
    };
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_finalize"></a>

## Function `finalize`

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_finalize">finalize</a>(h: &<b>mut</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Ripemd160">bitcoin_lib::ripemd160::Ripemd160</a>): vector&lt;u8&gt;
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>public</b> <b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_finalize">finalize</a>(h: &<b>mut</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_Ripemd160">Ripemd160</a>): vector&lt;u8&gt; {
    <b>let</b> <b>mut</b> pad: vector&lt;u8&gt; = vector[0x80];
    <b>let</b> <b>mut</b> i = 1;
    <b>while</b> (i &lt; 64) {
        pad.push_back(0);
        i = i + 1;
    };
    <b>let</b> bytes = h.bytes;
    <b>let</b> <b>mut</b> sizedecs: vector&lt;u8&gt; = vector[0, 0, 0, 0, 0, 0, 0, 0];
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE64">writeLE64</a>(&<b>mut</b> sizedecs, 0, bytes &lt;&lt; 3);
    h.<a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_write">write</a>(pad, 1 + ((119 - (bytes % 64)) % 64));
    h.<a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_write">write</a>(sizedecs, 8);
    <b>let</b> <b>mut</b> hash: vector&lt;u8&gt; = vector[];
    i = 0;
    <b>while</b> (i &lt; 20) {
        hash.push_back(0);
        i = i + 1;
    };
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE32">writeLE32</a>(&<b>mut</b> hash, 0, h.s[0]);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE32">writeLE32</a>(&<b>mut</b> hash, 4, h.s[1]);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE32">writeLE32</a>(&<b>mut</b> hash, 8, h.s[2]);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE32">writeLE32</a>(&<b>mut</b> hash, 12, h.s[3]);
    <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE32">writeLE32</a>(&<b>mut</b> hash, 16, h.s[4]);
    hash
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_veccopy"></a>

## Function `veccopy`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_veccopy">veccopy</a>(dest: &<b>mut</b> vector&lt;u8&gt;, dest_start: u64, src: vector&lt;u8&gt;, src_start: u64, len: u64)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_veccopy">veccopy</a>(dest: &<b>mut</b> vector&lt;u8&gt;, dest_start: u64, src: vector&lt;u8&gt;, src_start: u64, len: u64) {
    <b>let</b> <b>mut</b> i = dest_start;
    <b>let</b> <b>mut</b> j = src_start;
    <b>let</b> <b>mut</b> k = 0;
    <b>while</b> (k &lt; len) {
        <b>let</b> b = dest.borrow_mut(i);
        *b = src[j];
        i = i + 1;
        j = j + 1;
        k = k + 1;
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_writeLE64"></a>

## Function `writeLE64`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE64">writeLE64</a>(v: &<b>mut</b> vector&lt;u8&gt;, start_index: u64, x: u64)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE64">writeLE64</a>(v: &<b>mut</b> vector&lt;u8&gt;, start_index: u64, x: u64) {
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> <b>mut</b> x = x;
    <b>let</b> <b>mut</b> index = start_index;
    <b>while</b> (i &lt; 8) {
        // 64 bits
        <b>let</b> b = v.borrow_mut(index);
        *b = (x % 256) <b>as</b> u8;
        x = x / 256;
        index = index + 1;
        i = i + 1;
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_writeLE32"></a>

## Function `writeLE32`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE32">writeLE32</a>(v: &<b>mut</b> vector&lt;u8&gt;, start_index: u64, x: u32)
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_writeLE32">writeLE32</a>(v: &<b>mut</b> vector&lt;u8&gt;, start_index: u64, x: u32) {
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> <b>mut</b> x = x;
    <b>let</b> <b>mut</b> index = start_index;
    <b>while</b> (i &lt; 4) {
        // 64 bits
        <b>let</b> b = v.borrow_mut(index);
        *b = (x % 256) <b>as</b> u8;
        x = x / 256;
        i = i + 1;
        index = index + 1;
    }
}
</code></pre>

</details>

<a name="bitcoin_lib_ripemd160_readLE32"></a>

## Function `readLE32`

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(v: &vector&lt;u8&gt;, start_index: u64): u32
</code></pre>

<details>
<summary>Implementation</summary>

<pre><code><b>fun</b> <a href="../bitcoin_lib/ripemd160.md#bitcoin_lib_ripemd160_readLE32">readLE32</a>(v: &vector&lt;u8&gt;, start_index: u64): u32 {
    <b>let</b> <b>mut</b> ans = 0;
    <b>let</b> <b>mut</b> start_index = start_index;
    <b>let</b> <b>mut</b> base = 1;
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; 4) {
        ans = ans + base * (v[start_index] <b>as</b> u32);
        <b>if</b> (i == 3) {
            <b>break</b>
        };
        base = base * 256;
        i = i + 1;
        start_index = start_index + 1;
    };
    ans
}
</code></pre>

</details>
