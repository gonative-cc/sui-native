# nBTC Sui Contract Deployment

Guide for deploying and configuring the `nbtc` smart contract.

## Prerequisites

Before starting, ensure your Sui CLI is configured and you have the **Object ID** of your previously deployed `LightClient` (`bitcoin_spv`) contract.

## Deployment & Setup

The deployment process has been simplified. Instead of a two-step process with a post-publish `setup` function, the contract is now configured _before_ publishing by editing the `init` function directly in the source code.

### 1. Configure the Contract Source

Open the `nBTC/sources/nbtc.move` file and locate the `init` function. You must edit the placeholder values in this function before publishing.

**Key values to edit:**

- **`nbtc_bitcoin_script_pubkey`**: The hex-encoded `scriptPubKey` of your Bitcoin deposit address.
- **`@bitcoin_lc.to_id()`**: The Object ID of your `LightClient` contract. (move.toml)
- **`@fallback_addr`**: A default Sui address to receive funds if a mint's `OP_RETURN` is invalid. (move.toml)

  **CRITICAL**: The `nbtc_bitcoin_script_pubkey` value must be the **full `scriptPubKey`**, not just a Public Key Hash (PKH). An incorrect value will cause all minting transactions to fail.

### 2. Publish the Package

Once you have edited the `init` function and `move.toml` with your configuration, publish the package:

```bash
sui client publish --gas-budget 500000000
```

From the command's output, you can find your new **Package ID** and other created objects.

### 3. Post-Deployment Administration

After deployment, the `AdminCap` holder can change the active Bitcoin deposit script at any time by calling the `add_script_pubkey` function.
