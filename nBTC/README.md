<!-- markdownlint-disable MD041 -->
<!-- markdownlint-disable MD034 -->

# ![nBTC Logo!](../assets/nbtc.svg) nBTC

`nBTC` is the synthetic BTC on Sui, redeemable 1-1 for BTC (on Bitcoin).

It's the first ever synthetic BTC that is

- fully permission-less,
- custody-less,
- keeps the true Web3 ethos.
- rightmost trust minimized (read about [nBTC trust model](https://x.com/goNativeCC/status/1899487861939806641))

## Deployed Contracts

For information on deployed packages and object IDs on testnet/mainnet, please see the main [README](../README.md#deployed-objects--packages) file.

## Package Functions

- `init`: Run once to set up the `nBTC` package, initializes the nBTC Coin type and the TreasuryCap object (`WrappedTreasuryCap`).
- `mint`: Takes Bitcoin transaction proof, verifies it using the SPV light client, and mints `nBTC` Coins.
- `redeem`: Takes `nBTC` Coins and destroys them. Note: NOT IMPLEMENTED!
- `total_supply`: Shows the total amount of `nBTC` currently in circulation.
- `get_light_client_id`: Shows the Object ID of the SPV light client.
- `get_fallback_address`: Shows the default Sui address used when `OP_RETURN` data isn't usable.

### Dependencies

- `bitcoin_spv`: An on-chain Bitcoin SPV light client for verifying Bitcoin transactions.
- `bitcoin_parser`: A library for parsing Bitcoin data structures (blocks, transactions).

## Documentation

- [nBTC Setup](./docs/nbtc_setup.md)
- [nBTC Minting Process](./docs/nbtc_minting.md)

## UTXO Management

When users deposit Bitcoin to mint nBTC, those funds create UTXOs on the Bitcoin blockchain. The nBTC smart contract tracks these UTXOs so it can later spend them when users want to redeem their nBTC back to BTC on the Bitcoin chain.

### UTXO Structure

Each UTXO tracked by the system contains:

- `tx_id`: The Bitcoin transaction ID that created this output
- `vout`: The output index within the transaction
- `value`: The amount in satoshis
- `spend_key`: The scriptPubKey controlling this UTXO

### UTXO Selection Algorithm

For withdrawal requests, the system selects optimal UTXOs to minimize transaction fees, avoid dust outputs, and maintain efficient key rotation. The ranking algorithm evaluates UTXO combinations based on the following criteria:

#### Ranking Criteria

1. **Exact matches** (+1,000 points): Combinations that produce zero change output
2. **Dust avoidance** (-200 points): Penalizes change outputs below 10,000 satoshis
3. **Key rotation** (+200 points per UTXO): Prioritizes spending from inactive keys
4. **Input minimization** (-100 points per input): Reduces transaction size and fees

#### Scoring Formula

```text
score = BASE_SCORE
      - (number_of_inputs × 100)
      + (inactive_key_count × 200)
      + 1,000 (if change = 0)
      - 200 (if 0 < change < 10,000)
```

The algorithm selects the combination with the highest score. A score of 0 indicates insufficient funds.

**Constants:**

- `DUST_THRESHOLD`: 10,000 satoshis
- `BASE_SCORE`: 4,000,000,000,000,000
- `INPUTS_PENALTY`: 100
- `INACTIVE_BONUS`: 200
- `NO_CHANGE_BONUS`: 1,000
- `DUST_PENALTY`: 200

### UTXO Validation

Before executing a withdrawal, the system validates:

1. **Non-empty set**: The UTXO set must contain at least one element
2. **Existence verification**: All proposed UTXOs must exist in the on-chain UTXO table
3. **Sufficient value**: Total UTXO value must meet or exceed the withdrawal amount

If validation fails, the transaction is aborted with an appropriate error code.

### Implementation

The UTXO management implementation is in [nBTC/sources/utxo.move](./sources/utxo.move):

- `utxo_ranking()`: Calculates the ranking score for a UTXO set given a withdrawal amount and active key
- `validate_utxos()`: Validates proposed UTXOs against the on-chain UTXO table
- `new_utxo()`: Constructor for UTXO struct
- `tx_id()`, `vout()`, `value()`, `spend_key()`: Accessor functions for UTXO fields
