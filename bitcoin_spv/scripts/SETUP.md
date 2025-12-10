# Light Client Initializer

This script initializes a Bitcoin SPV (Simplified Payment Verification) light client on the Sui network using parameters from a `.env` file.

## Prerequisites

- **Bun** (JavaScript/TypeScript runtime)
- **Sui CLI** (for publishing packages)

## Setup

1. Install dependencies:

```bash
bun install
```

2. Publish the required Sui packages:

   ```bash
   sui client publish
   ```

3. Create a `.env` file with your configuration (see example below).

## Usage

Run the script to initialize the light client on-chain:

```bash
bun run new_light_client.ts
```

Note: The script uses TypeScript, so run it with `bun run` or compile it first.

## Environment Variables

### Required Variables

| Variable                 | Description                                                               | Example       |
| ------------------------ | ------------------------------------------------------------------------- | ------------- |
| `SPV_PACKAGE_ID`         | ID of the deployed light client package                                   | `0x123...`    |
| `BITCOIN_LIB_PACKAGE_ID` | ID of the deployed bitcoin_lib package                                    | `0x456...`    |
| `HEADERS`                | Comma-separated list of hex-encoded Bitcoin block headers (80 bytes each) | `0x...,0x...` |
| `BTC_NETWORK`            | Bitcoin network identifier (0=mainnet, 1=testnet, 2=regtest)              | `2`           |
| `BTC_HEIGHT`             | Starting block height                                                     | `0`           |
| `PARENT_CHAIN_WORK`      | Initial parent chain work (hex string)                                    | `0`           |
| `CONFIRMATION_DEPTH`     | Confirmation depth requirement (inclusive)                                | `3`           |

### Optional Variables

| Variable    | Description                                              | Default   |
| ----------- | -------------------------------------------------------- | --------- |
| `NETWORK`   | Sui network ('mainnet', 'testnet', 'devnet', 'localnet') | `testnet` |
| `MNEMONIC`  | Sui wallet mnemonic phrase (alternative to ENCODE_SK)    | -         |
| `ENCODE_SK` | Base64-encoded private key (alternative to MNEMONIC)     | -         |

## `.env` Example

```dotenv
# Sui wallet credentials (one of these is required)
MNEMONIC='word1 word2 word3 ...'
# ENCODE_SK='...'

# Package IDs from publish output
SPV_PACKAGE_ID='0x...'
BITCOIN_LIB_PACKAGE_ID='0x...'

# Sui network (defaults to testnet if not specified)
NETWORK='testnet'

# Bitcoin block headers (comma-separated, 80 bytes each, hex-encoded)
HEADERS='0x000000208ec39e00922e223962f32626847a49df4ef2875ec9c4dd5b680000000000000000003bba30156888c06e5126a6e4ca28cc8a8178283f938416138d50ee0db30bf2e80c0b8265a01a5445babe2c8e105201e75a56b047ec5e70d948b5365950fe510852b00100000000'

# Bitcoin network settings
BTC_NETWORK=2
BTC_HEIGHT=0
PARENT_CHAIN_WORK=0
CONFIRMATION_DEPTH=3
```

## Notes

- The script validates that each Bitcoin header is exactly 80 bytes (160 hex characters)
- Headers must be hex-encoded and start with `0x`
- Confirmation depth is inclusive - the block containing the transaction counts as the first confirmation
- You need either `MNEMONIC` or `ENCODE_SK` for wallet access
