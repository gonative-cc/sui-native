# Guide: Mint nBTC on Sui from Bitcoin

This guide shows how to create a Bitcoin transaction and use it to mint nBTC on the Sui network using the provided scripts.

## Requirements

- `bitcoind` & `bitcoin-cli` (with funded wallet)
- `jq`
- `sui`
- Python 3
- The scripts: `compose_bitcoin_tx.sh`, `sui-mint-nbtc.sh`, `extract_btc_data.sh`, `create_nbtc_proof.py` (make sure `.sh` files are executable: `chmod +x *.sh`)

## Steps

### 1. Create Bitcoin Transaction

Run `compose_bitcoin_tx.sh` with the recipient address, amount (in BTC), and your OP_RETURN data (hex representation of the Sui address you want the nBTC to be minted to).
This script will create, sign (check bitcoin-cli wallet [guide](https://github.com/BlockchainCommons/Learning-Bitcoin-from-the-Command-Line/blob/master/03_3_Setting_Up_Your_Wallet.md)) and send a Bitcoin nBTC deposit transaction.

```bash
./compose_bitcoin_tx.sh tb1q... 0.00005 c762...
```

This script will print a TXID. Copy it.

### 2. Wait for Confirmations

Wait until your Bitcoin transaction has enough confirmations (e.g., 8 confirmations) on the Bitcoin network. You can check this using a block explorer or bitcoin-cli.

### 3. Mint nBTC on Sui

Run mint.sh with the confirmed TXID from Step 1.

```bash
./sui-mint-nbtc.sh <your_confirmed_txid_here>
```
