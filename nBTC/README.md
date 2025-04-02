![nBTC Logo!](../assets/nBTC.png)

# nBTC

`nBTC` is the synthetic Bitcoin on Sui, redeemable 1-1 for BTC.

It's the first ever synthetic BTC (BTC that is represented on other chain) that is

- fully permissionless,
- custodyless,
- rightmost trust minimized (read about [nBTC trust model](https://x.com/goNativeCC/status/1899487861939806641))
- keeps the true Web3 ethos.

## How it Works

1.  A user sends BTC to to the `nBTC` dwallet address (on Bitcoin network). They include their target Sui address in the transaction's `OP_RETURN` field.
2.  The user calls the `mint` function of the `nBTC` Sui object, providing the BTC transaction details and the proof of the transaction. The proof is the traditional SPV Bitcoin proof.
3.  The `mint` function uses a configured Bitcoin SPV Light Client (identified by `LIGHT_CLIENT_ID`) to verify the transaction proof. It checks that BTC was sent to the correct `nBTC` dwallet address.
4.  Once the verification is successful and the BTC transaction hasn't been used before, the module mints the corresponding amount of `nBTC` Sui Coins.
5.  The new `nBTC` Coins are sent to the Sui address found in the `OP_RETURN` data, or to the `FALLBACK_ADDRESS` if the `OP_RETURN` data is missing or is invalid.

### Example

TODO: Add example Bitcoin transaction

## Package Functions

- `init`: Run once to set up the `nBTC` package, initializes the nBTC Coin type and the TreasuryCap object (`WrappedTreasuryCap`).
- `mint`: Takes BTC transaction proof, verifies it using the SPV light client, and mints new `nBTC` Coins.
- `burn`: Takes `nBTC` Coins and destroys them. Note: NOT IMPLEMENTED!
- `total_supply`: Shows the total amount of `nBTC` currently in circulation.
- `get_light_client_id`: Shows the Object ID of the SPV light client.
- `get_fallback_address`: Shows the default Sui address used when `OP_RETURN` data isn't usable.

## Dependencies

- `bitcoin-spv`: This package relies on a Bitcoin SPV light client implementation for Sui to verify txs from Bitcoin https://github.com/gonative-cc/move-bitcoin-spv.

## Flowchart

```mermaid
graph TD
    A["User sends BTC to nBTC dwallet address <br> (adds OP_RETURN with Sui Address)"] --> B("User obtains BTC Transaction Proof (SPV)");
    B --> C{"User calls mint function on nBTC Sui object <br> (Provides Proof, TX Details)"};
    C --> D("Module uses configured <br> Bitcoin SPV Light Client Object <br> (specified by LIGHT_CLIENT_ID)");
    D --> E{"SPV Client verifies the transaction proof <br> (Checks inclusion, amount, target: nBTC dwallet address)"};
    E -- Verification Successful --> F{"Internal Checks in nBTC module: <br> 1. Is BTC TX ID already used? <br> 2. Is verified Amount > 0?"};
    F -- Checks Pass --> G{"Determine Recipient Sui Address <br> (Parse OP_RETURN data from proof)"};
    G -- Valid OP_RETURN --> H("Mint nBTC Sui Coins <br> Transfer to Recipient Address");
    G -- Invalid/No OP_RETURN --> I("Mint nBTC Sui Coins <br> Transfer to FALLBACK_ADDRESS");
    H --> Z(["Success: nBTC Minted & Transferred"]);
    I --> Z;
    F -- Checks Fail --> Y(["Error: e.g., TxAlreadyUsed, AmountIsZero"]);
    E -- Verification Failed --> Y;
```
