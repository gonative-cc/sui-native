# nBTC Sui Move Contract

## Overview

This Sui Move smart contract implements `NBTC`, a Native's synthetic representation of Bitcoin on the Sui network. It allows users to mint `NBTC` tokens by providing proof of a corresponding Bitcoin deposit transaction, verified using an on-chain SPV (Simple Payment Verification) light client.

## Features

1. Minting: Creates new `NBTC` tokens based on verified Bitcoin deposits.
2. Burning: Allows destruction of `NBTC` tokens.
3. SPV Verification: Uses the `bitcoin-spv` Sui package to verify Bitcoin transactions using SPV proofs via a trusted `LightClient` object.
4. OP_RETURN Recipient: Attempts to determine the mint recipient from the Bitcoin transaction's `OP_RETURN` data.
5. Double-Spend Prevention: Tracks used Bitcoin transaction IDs to prevent minting the same deposit multiple times.
6. Coin Standard: Implements `NBTC` as a standard Sui Coin with 8 decimals.

## Dependencies

- `bitcoin-spv` Package: Requires a deployed version of the `bitcoin-spv` package, specifically needing access to a shared `LightClient` object and its associated functions (`make_transaction`, `prove_payment`).

## Events

* **`TreasuryCreated { treasury_id: ID }`**: Emitted when the `WrappedTreasuryCap` is created in `init`.
* **`NBTCMited { minted_to: address, amount_in_satoshi: u64 }`**: Emitted upon successful minting.

## Disclaimer

DO NOT USE IT IN PRODUCTION!!!  NOT TESTED!!!
