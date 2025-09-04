# nBTC Sui Contract Deployment

Guide for deploying and configuring the `nbtc` smart contract.

## Prerequisites

Before starting, ensure your Sui CLI is configured and you have the **Object ID** of your previously deployed `LightClient` (`bitcoin_spv`) contract.

## Deployment & Setup

The process involves two steps: publishing the package and then calling the `setup` function to configure it.

### 1. Publish the Package

This command deploys the contract and creates the `WrappedTreasuryCap` object.

```bash
sui client publish
```

From the command's output, save the new **Package ID** and the **`WrappedTreasuryCap` Object ID**.

### 2. Configure the Treasury

Next, call the one-time `setup` function to link the treasury to your light client and Bitcoin escrow address.

```bash
sui client call \
  --package <YOUR_NBTC_PACKAGE_ID> \
  --module nbtc \
  --function setup \
  --args <YOUR_WRAPPED_TREASURY_ID> <LIGHT_CLIENT_OBJECT_ID> <FALLBACK_SUI_ADDRESS> <YOUR_BTC_ESCROW_PKH_HEX> \
```

**Argument Breakdown:**

- **`<YOUR_WRAPPED_TREASURY_ID>`**: The `WrappedTreasuryCap` ID from the publish step.

- **`<LIGHT_CLIENT_OBJECT_ID>`**: The `LightClient` object ID from your prerequisites.

- **`<FALLBACK_SUI_ADDRESS>`**: A Sui address to receive funds if a mint's `OP_RETURN` is invalid.

- **`<YOUR_BTC_ESCROW_PKH_HEX>`**: The hex-encoded Public Key Hash of your Bitcoin deposit address.

  **CRITICAL**: This value must be the **20-byte Public Key Hash (PKH)** only, _not_ the full `scriptPubKey`. An incorrect value will cause all minting transactions to fail.

  - **Correct (PKH only):** `0x9201782d57fa256bc74146871bb662f099c1f539`
  - **Incorrect (with script prefix):** `0x00149201782d57fa256bc74146871bb662f099c1f539`
