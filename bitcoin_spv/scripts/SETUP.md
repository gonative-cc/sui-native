# Light Client Initializer

This script initializes a Bitcoin SPV light client on Sui network.

## Setup

1. Install dependencies:

```bash
bun install
```

1. Publish packages:

```bash
sui client publish
```

1. Edit `config.ts`:
   - Replace package IDs with your deployed package IDs
   - Update network settings
   - Replace headers with your trusted Bitcoin block headers

1. Create `.env` with your wallet credentials:

```env
MNEMONIC='your mnemonic here'
# or
WALLET_SK='base64-encoded private key'
```

1. Run the script:

```bash
bun run new_light_client.ts
```

## Configuration

Edit the `getLightClientConfig()` function in `config.ts`:

| Field                   | Description                                                 | Example            |
| ----------------------- | ----------------------------------------------------------- | ------------------ |
| **spvPackageId**        | Deployed package ID for Bitcoin SPV contract                | "0x123..."         |
| **bitcoinLibPackageId** | Deployed package ID for Bitcoin library                     | "0x456..."         |
| **network**             | Sui network to deploy to                                    | "testnet"          |
| **headers**             | Array of trusted Bitcoin block headers (at least 11 blocks) | ["0x...", "0x..."] |
| **btcNetwork**          | Bitcoin network (0=mainnet, 1=testnet, 2=regtest)           | 2                  |
| **btcHeight**           | Starting block height                                       | 0                  |
| **parentChainWork**     | Parent chain work (hex)                                     | "0"                |
| **confirmationDepth**   | Required confirmations                                      | 3                  |

## Notes

- Only MNEMONIC or WALLET_SK need to be in .env file
- All other configuration is in config.ts for better type safety
- Configuration is validated before deployment
