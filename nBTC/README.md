<!-- markdownlint-disable MD041 -->
<!-- markdownlint-disable MD034 -->

# ![nBTC Logo!](../assets/nbtc.svg) nBTC

`nBTC` is the synthetic BTC on Sui, redeemable 1-1 for BTC (on Bitcoin).

It's the first ever synthetic BTC that is

- fully permission-less,
- custody-less,
- keeps the true Web3 ethos.
- rightmost trust minimized (read about [nBTC trust model](https://x.com/goNativeCC/status/1899487861939806641))
- NBTC_BITCOIN_PKH = 0xce9f3ad7d227c66e9744d052821c20d18a2ea78f. Corresponds to `tb1qe60n447jylrxa96y6pfgy8pq6x9zafu09ky7cq` address on Bitcoin testnet.

## Deployment

We need to run PTB with 2 transactions: publish nbtc + move call for setup method.

## Deployed contracts

See the main [README](../README.md#deployed-objects--packages) file.

## Package Functions

- `init`: Run once to set up the `nBTC` package, initializes the nBTC Coin type and the TreasuryCap object (`WrappedTreasuryCap`).
- `mint`: Takes Bitcoin transaction proof, verifies it using the SPV light client, and mints `nBTC` Coins.
- `redeem`: Takes `nBTC` Coins and destroys them. Note: NOT IMPLEMENTED!
- `total_supply`: Shows the total amount of `nBTC` currently in circulation.
- `get_light_client_id`: Shows the Object ID of the SPV light client.
- `get_fallback_address`: Shows the default Sui address used when `OP_RETURN` data isn't usable.

### Dependencies

- `bitcoin-spv`: This package depends on a Bitcoin SPV light client to verify txs from Bitcoin https://github.com/gonative-cc/move-bitcoin-spv.

## Documentation

- [Minting](./docs/nbtc_minting.md)
