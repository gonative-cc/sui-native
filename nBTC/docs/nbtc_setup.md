# nBTC Sui Contract Deployment

Guide for deploying and configuring the `nbtc` smart contract.

## Prerequisites

Before starting, ensure your Sui CLI is configured and you have the **Object ID** of your previously deployed `LightClient` (`bitcoin_spv`) contract.

## Deployment & Setup

The deployment process has been simplified. Instead of a two-step process with a post-publish `setup` function, the contract is now configured _before_ publishing by editing the `init` function directly in the source code.

### 1. Configure the Contract Source

Open the `nBTC/sources/nbtc.move` file and locate the `init` function. You must edit the placeholder values in this function before publishing.

**Key values to edit:**

- **`nbtc_spend_key`**: The hex-encoded `scriptPubKey` of your Bitcoin deposit address.
- **`@bitcoin_lc.to_id()`**: The Object ID of your `LightClient` contract. (move.toml)
- **`@fallback_addr`**: A default Sui address to receive funds if a mint's `OP_RETURN` is invalid. (move.toml)

  **CRITICAL**: The `nbtc_spend_key` value must be the **full `scriptPubKey`**, not just a Public Key Hash (PKH). An incorrect value will cause all minting transactions to fail.

### 2. Publish the Package

Once you have edited the `init` function and `move.toml` with your configuration, publish the package:

```bash
sui client publish --gas-budget 500000000
```

From the command's output, you can find your new **Package ID** and other created objects.

### 3. Register NBTC Currencty

We use `init` with OTW for initialization. We must call finalize_registration to promote the currency to the registry. [Details](https://docs.sui.io/standards/currency#coin-finalization).

```bash
sui client ptb \
  --move-call 0x2::coin_registry::finalize_registration @0xc <NBTC_ID>
```

### 3. Post-Deployment Administration

After deployment, the `AdminCap` holder can change the active Bitcoin deposit script at any time by calling the `add_script_pubkey` function.
