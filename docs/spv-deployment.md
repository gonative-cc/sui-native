# SPV Light Client Deployment Guide

This guide explains how to deploy a new Bitcoin SPV (Simplified Payment Verification) light client on the Sui network.

## Prerequisites

### Environment Setup

Create `.env` file with your key to sign Sui transactions:

```env
# Bitcoin Indexer URL (optional, defaults to regtest)
INDEXER_URL=http://localhost:8080/regtest

# Sui key for creating setup transactions
MNEMONIC="your twelve word mnemonic phrase"
# OR
WALLET_KEY="base64-encoded private key"
```

### Dependencies.

The following packages must be published:

- `bitcoin_lib` package must be published
- `bitcoin_spv` package must be published

If they are not you can use the following script to publish them

````bash
bun run scripts/publish.ts bitcoin_spv

## Deployment


Deploy just the SPV light client using published packages:

```bash
bun run deploy:spv
````

## Configuration

The deployment process uses `deploy-information.json` to store configuration:

```json
{
  "sui_network": "testnet",
  "btc_network": "regtest",
  "bitcoin_lib_pkg": "0x...",
  "lc_pkg": "0x...",
  "lc_contract": "0x...",
  "height": 100,
  "header_count": 11,
  "sui_fallback_address": "0x..."
}
```

Here is the meaning of the fields:

| Field             | Description                       | Default                   |
| ----------------- | --------------------------------- | ------------------------- |
| `height`          | Starting block height for headers | 0                         |
| `header_count`    | Number of headers to fetch        | 11                        |
| `bitcoin_lib_pkg` | Bitcoin library package ID        | From Published.toml       |
| `lc_pkg`          | Light client package ID           | From Published.toml       |
| `lc_contract`     | Light client contract instance ID | Created during deployment |

## Bitcoin Headers

The light client requires trusted Bitcoin block headers:

1. **Minimum Required**: At least 11 consecutive headers
2. **Source**: Fetched from indexer at `INDEXER_URL`
3. **Process**: Headers are validated and stored in the light client contract

## Deployment Process

1. Configuration Loading:
   - Reads `deploy-information.json` (creates if missing)
   - Validates network consistency
   - Fetches package IDs from `Published.toml`

2. **Header Fetching**:
   - Connects to Bitcoin indexer
   - Fetches `header_count` blocks starting from `height`
   - Validates header format and chain continuity

3. **Light Client Creation**:
   - Creates Move BlockHeader objects
   - Calls `initialize_light_client` function
   - Stores headers in the light client contract

4. **State Persistence**:
   - Saves light client contract ID to `deploy-information.json`
   - Records height and header count used
   - Updates package IDs if from Published.toml
