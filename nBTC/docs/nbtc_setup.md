# nBTC Sui Contract Deployment

Guide for deploying and configuring the `nbtc` smart contract.

## Automated Deployment (Recommended)

The project provides an automated deployment script that handles the entire setup process, including the Bitcoin Light Client, nBTC package, and dWallet.

### Quick Start

```bash
bun run deploy-nbtc
```

This script:

- Reads package IDs from `Published.toml` for already deployed packages
- Checks for mismatches between `deploy-information.json` and `Published.toml`
- Deploys or reuses the Bitcoin Light Client
- Publishes the nBTC package with proper configuration
- Creates and initializes a dWallet
- Saves all deployment details to `deploy-information.json`

### Deployment Information

The deployment process saves state to `deploy-information.json` in the project root:

```typescript
{
  "btc_network": "regtest", // Bitcoin network (e.g., "regtest", "mainnet", "testnet")
  "sui_network": "testnet", // Sui network (e.g., "testnet", "mainnet", "devnet")
  "bitcoin_lib_pkg": "0x...bitcoin_lib_package_id", // Bitcoin library package ID for utilities
  "lc_pkg": "0x...light_client_package_id", // Light Client (bitcoin_spv) package ID
  "lc_contract": "0x...light_client_object_id", // Light Client shared object ID
  "nbtc_pkg": "0x...nbtc_package_id", // nBTC Move package ID
  "nbtc_contract": "0x...nbtc_contract_object_id", // nBTC shared contract object ID
  "nbtc_admin_cap": "0x...admin_cap_object_id", // Admin capability for managing nBTC
  "sui_fallback_address": "0x...fallback_sui_address", // Fallback Sui address for invalid mint OP_RETURN
  "btc_address": "bcrt1q...dwallet_btc_address", // dWallet Bitcoin deposit address
  "dwallet_id": "0x...dwallet_object_id" // dWallet object ID for Bitcoin operations
  "height": 0, // spv init height
}
```

### Clean Deployment

To start with a fresh deployment:

```bash
bun run deploy:cleanup
bun run deploy-nbtc
```

To force republish packages (delete Published.toml files):

```bash
bun run publish:cleanup
bun run deploy-nbtc
```

**Note**: If `deploy-information.json` and `Published.toml` have mismatched package IDs, the script will display an error. Either fix the mismatch or delete `deploy-information.json`.

## Environment Variables

Copy `.env.example` to `.env` in the project root:

- `MNEMONIC` or `WALLET_SK` - Sui wallet credentials (one required)
- `INDEXER_URL` - Bitcoin indexer URL

For manual nBTC deployment only:

- `BITCOIN_LC` - Light client object ID
- `FALLBACK_ADDR` - Fallback Sui address

Note: IKA coordinator is automatically retrieved from the SDK.

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
