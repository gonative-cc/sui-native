![nBTC Logo!](../assets/nBTC.png)

# nBTC

`nBTC` is the synthetic Bitcoin on Sui, redeemable 1-1 for BTC.

It's the first ever synthetic BTC (BTC that is represented on other chain) that is

- fully permissionless,
- custodyless,
- rightmost trust minimized (read about [nBTC trust model](https://x.com/goNativeCC/status/1899487861939806641))
- keeps the true Web3 ethos.

## How it Works

1.  A user sends BTC to a specific Bitcoin address (`BTC_TREASURY`). They include their target Sui address in the transaction's `OP_RETURN` field.
2.  The user calls the `mint` function, providing the BTC transaction details and the proof.
3.  The `mint` function uses a configured Bitcoin SPV Light Client (identified by `TRUSTED_LIGHT_CLIENT_ID`) to verify the transaction proof. It checks that BTC was sent to the correct `BTC_TREASURY` address.
4.  If the verification is successful and the BTC transaction hasn't been used before, the module creates (`mints`) the corresponding amount of `NBTC`.
5.  The new `NBTC` tokens are sent to the Sui address found in the `OP_RETURN` data, or to a default `FALLBACK_ADDRESS` if the `OP_RETURN` data is missing or invalid.

## Main Functions

- `init`: Run once to set up the `nBTC` token type and the TreasuryCap object (`WrappedTreasuryCap`).
- `mint`: Takes BTC transaction proof, verifies it using the SPV light client, and mints new `nBTC` tokens.
- `burn`: Takes `NBTC` tokens and destroys them. Note: NOT IMPLEMENTED!
- `total_supply`: Shows the total amount of `nBTC` currently in circulation.
- `get_trusted_light_client_id`: Shows the Object ID of the SPV light client this contarct trusts.
- `get_fallback_address`: Shows the default Sui address used when `OP_RETURN` data isn't usable.

## Dependencies

- `bitcoin-spv`: This contract relies on a Bitcoin SPV light client implementation for Sui to verify txs from Bitcoin https://github.com/gonative-cc/move-bitcoin-spv.
