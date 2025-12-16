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
- [UTXO Management](./docs/utxo_management.md)
- [nBTC Minting Process](./docs/nbtc_minting.md)
- [nBTC Redeem Process](./docs/nbtc_redeem.md)

### Model

```mermaid
classDiagram
    class NbtcContract {
        +confirm_redeem(light_client: LightClient, redeem_id: u64, tx_bytes: vector_u8, proof: vector_vector_u8, height: u64, tx_index: u64)
        +validate_signature(dwallet_coordinator: DWalletCoordinator, redeem_id: u64)
        +redeem(redeem_id: u64): u64
        +update_redeem_utxo_and_burn(redeem_id: u64, tx_id: vector_u8, tx: Transaction)
        +config(): NbtcConfig
        +active_dwallet_id(): address
        locked: map_u64_to_coin
        redeem_requests: map_u64_to_RedeemRequest
        utxo_store: UtxoStore
        cap: NbtcCap
        version: u64
    }

    class RedeemRequest {
        status: RedeemStatus
        inputs: vector_Utxo
        +status(): RedeemStatus
        +raw_signed_tx(storage: NbtcStorage): vector_u8
        +utxo_ids(): vector_u64
        +dwallet_ids(): vector_address
        +move_to_signing_status(redeem_id: u64)
        +move_to_confirmed_status(redeem_id: u64, tx_id: vector_u8)
        +request_signature_for_input(dwallet_coordinator: DWalletCoordinator, input_idx: u32)
    }

    class RedeemStatus {
        <<enum>>
        +Pending
        +Signing
        +Resolving
        +Confirmed
        +is_signed(): bool
        +is_resolving(): bool
    }

    class ConfirmedEvent {
        <<event>>
        +id: u64
        +inputs: vector_Utxo
        +tx_id: vector_u8
    }

    class LightClient {
        +verify_tx(height: u64, tx_id: vector_u8, proof: vector_vector_u8, tx_index: u64): bool
        +id(): address
    }

    class Transaction {
        +tx_id(): vector_u8
        +outputs(): vector_TxOutput
    }

    class TxOutput {
        +amount(): u64
    }

    class UtxoStore {
        +unlock_utxo(utxo_id: u64, dwallet_id: address)
        +remove(utxo_id: u64, dwallet_id: address)
        +add(dwallet_id: address, utxo: Utxo)
    }

    class Utxo {
        +tx_id: vector_u8
        +index: u32
        +amount: u64
    }

    class NbtcCap {
        +burn(amount: coin)
    }

    class NbtcConfig {
        +light_client_id(): address
    }

    class DWalletCoordinator
    class NbtcStorage

    NbtcContract --> RedeemRequest : manages
    NbtcContract --> UtxoStore : owns
    NbtcContract --> NbtcCap : controls
    NbtcContract --> NbtcConfig : reads
    NbtcContract --> LightClient : verifies_tx
    NbtcContract --> Transaction : decodes
    RedeemRequest --> RedeemStatus : uses
    RedeemRequest --> ConfirmedEvent : emits
    Transaction --> TxOutput : contains
    UtxoStore --> Utxo : stores
    RedeemRequest --> Utxo : inputs
    RedeemRequest --> DWalletCoordinator : requests_signatures
    RedeemRequest --> NbtcStorage : reads_raw_signed_tx
```
