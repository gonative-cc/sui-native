# nBTC Sui Contract Deployment

Guide for deploying and configuring the `nbtc` smart contract.

## Automated Deployment (Recommended)

The project provides an automated deployment script that handles the entire setup process, including the Bitcoin Light Client, nBTC package, and dWallet.

### Quick Start

```bash
bun run deploy-nbtc
```

This script:

- Checks for existing deployments in `deploy-information.json`
- Deploys or reuses the Bitcoin Light Client
- Publishes the nBTC package with proper configuration
- Creates and initializes a dWallet
- Saves all deployment details to `deploy-information.json`

### Deployment Information

The deployment process saves state to `deploy-information.json` in the project root:

```typescript
{
  btc_network?: string;           // Bitcoin network (e.g., "regtest")
  sui_network?: string;          // Sui network (e.g., "testnet")
  bitcoin_lib_pkg?: string;       // Published bitcoin_lib package ID
  lc_pkg?: string;               // Published bitcoin_spv (light client) package ID
  lc_contract?: string;           // Light client object ID
  nbtc_pkg?: string;            // Published nBTC package ID
  nbtc_contract?: string;        // nBTC contract object ID
  nbtc_admin_cap?: string;       // Admin capability object ID
  sui_fallback_address?: string; // Fallback Sui address
  btc_address?: string;          // dWallet Bitcoin address
  dwallet_id?: string;          // dWallet object ID
}
```

### Clean Deployment

To start with a fresh deployment:

```bash
bun run deploy:clean
bun run deploy-nbtc
```

## Environment Variables

Copy `.env.example` to `.env` in the project root:

- `MNEMONIC` or `ENCODE_SK` - Sui wallet credentials (one required)
- `INDEXER_URL` - Bitcoin indexer URL

For manual nBTC deployment only:

- `BITCOIN_LC` - Light client object ID
- `FALLBACK_ADDR` - Fallback Sui address

Note: IKA coordinator is automatically retrieved from SDK.

---

## Manual Deployment

Below is the manual deployment process if you prefer not to use the automated script.

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

### 3. Register NBTC Currency

We use `init` with OTW for initialization. We must call `finalize_registration` to promote the currency to the registry. [Details](https://docs.sui.io/standards/currency#coin-finalization).

```bash
sui client ptb \
  --move-call 0x2::coin_registry::finalize_registration @0xc <NBTC_ID>
```

### 4. Post-Deployment Administration

After deployment, the `AdminCap` holder can change the active Bitcoin deposit script at any time by calling the `add_script_pubkey` function.
