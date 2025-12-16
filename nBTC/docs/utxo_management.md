# UTXO Management

When users deposit Bitcoin to mint nBTC, those funds create UTXOs on the Bitcoin blockchain. The nBTC smart contract tracks these UTXOs so it can later spend them when users want to redeem their nBTC back to BTC on the Bitcoin chain.

### UTXO Structure

Each UTXO tracked by the system contains:

- `tx_id`: The Bitcoin transaction ID that created this output
- `vout`: The output index within the transaction
- `value`: The amount in satoshis
- `spend_key`: The scriptPubKey controlling this UTXO

### Implementation

The UTXO management implementation is in [nBTC/sources/utxo.move](./sources/utxo.move):

- `utxo_ranking()`: Calculates the ranking score for a UTXO set given a withdrawal amount and active key
- `validate_utxos()`: Validates proposed UTXOs against the on-chain UTXO table
