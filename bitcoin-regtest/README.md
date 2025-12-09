# Bitcoin Regtest Setup

Docker Compose setup for Bitcoin Regtest with Esplora explorer.

## Quick Start

1. Start services:
   ```bash
   docker-compose up -d
   ```

2. Access web interface: `http://localhost:8080`

3. Stop services:
   ```bash
   docker-compose down
   ```

## API Endpoints

### Transaction Query
```bash
curl http://localhost:8080/regtest/api/tx/{txid}/hex
```

### Block Query
```bash
# Get block by hash
curl http://localhost:8080/regtest/api/block/{blockhash}

# Get block by height
curl http://localhost:8080/regtest/api/block-height/{height}
```

### Address Query
```bash
curl http://localhost:8080/regtest/api/address/{address}
```

## Services

- **esplora-regtest**: Blockstream Esplora explorer on port 8080
- **Data**: Stored in `./esplora-regtest-data/`