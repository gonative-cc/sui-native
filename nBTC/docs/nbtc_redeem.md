# nBTC Redeem

Prerequisites:

- [UTXO Management](./utxo_management.md)
- [nBTC Minting Process](./nbtc_minting.md)

This document outlines the requirements for a Bitcoin transaction to be recognized as a valid nBTC deposit by the smart contract.

## Flow

1. User sends `nBTC` to the `NbtcContract` smart contract and creates `RedeemRequest`.
1. UTXO selection phase starts: for the next `NbtcContract.redeem_duration` milliseconds everyone can propose a UTXO set to redeem.
   - `RedeemRequest` should remember the best selection and corresponding UTXOs should be temporarily locked by `NbtcContract`.
   - If no valid UTXO set is proposed during `redeem_duration`, the UTXO selection phase continues until a valid UTXO set is proposed.
   - New, better UTXO set can use UTXOs from the former ("current") `RedeemRequest` best UTXO set, but it can't use UTXOs from another `RedeemRequest`.
   - When a new, better UTXO set is proposed, UTXOs from the previous set should be unlocked.
1. After the UTXO selection phase, anyone can trigger Ika SignRequest phase. `NbtcContract` will create Ika SignRequest for every UTXO.
1. System should observe completion of Ika SignRequests and validate it.
1. Once all UTXOs are signed, the `NbtcContract` will compose the final BTC withdraw transaction and emit it in an event. Broadcasting Phase begins.
1. Now, anyone can broadcast the transaction.
1. Once the withdraw transaction is minted and has sufficient confirmations, anyone can send a proof of confirmation of the transaction, to finalize the SignRequest and delete UTXOs.

## Transaction Overview

To mint `nBTC` user must broadcast a Bitcoin transaction containing:

1.  **Funding Inputs**: Standard Bitcoin inputs.
1.  **Deposit Output**: A transfer to the nBTC DWallet.
1.  **Instruction Output**: An `OP_RETURN` payload specifying the destination address on Sui.
1.  **Change Outputs**: Returning excess funds.

### Inputs

Standard Bitcoin inputs (P2PKH, P2WPKH, P2TR, etc.).

### Outputs Structure & Validation

The nBTC contract parses transaction outputs (from index 0). It applies a **"First Match"** policy
for identifying relevant outputs.

#### A. Deposit Output (The Payment)

This output defines the amount of `BTC` to be minted in form of `nBTC` on Sui.

- **Script**: Must strictly match the active **nBTC DWallet lock script** (e.g., the specific P2WPKH
  or P2TR script hash registered in the contract, if the contract only registered one for eg, P2TR,
  any other scripts destined to this address will be ignored).
- **Amount**: Must be > 0 satoshis.
- **Parsing Rule**: The system scans outputs in order. The **first** output matching the registered
  script is recorded as the `nBTC` deposit.
- _Warning_: Any subsequent outputs to the same address in the same transaction are ignored.

#### B. Instruction Output (OP_RETURN)

This output specifies where the minted nBTC will be sent on the Sui network.

- **Type**: `OP_RETURN`.
- **Parsing Rule**: The system scans outputs in order. The **first** `OP_RETURN` output found is
  treated as the instruction.
- _Fallback_: If no `OP_RETURN` is present, or if it is malformed, funds are minted to the
  contract's default **Fallback Address**.

#### Payload Schema

The `OP_RETURN` data must follow this byte-level format exactly:

| Byte Offset | Field          | Length   | Value      | Description                               |
| :---------- | :------------- | :------- | :--------- | :---------------------------------------- |
| `0`         | `payload_type` | 1 byte   | `0x00`     | Indicator for "Direct Transfer".          |
| `1`         | `recipient`    | 32 bytes | `[u8; 32]` | The 32-byte Sui address of the recipient. |

- **Total Payload Length**: Exactly **33 bytes**.
- **Invalid Payloads**:
  - If `payload_type` is not `0x00` -> **Fallback**.
  - If total length is not 33 bytes -> **Fallback**.
  - If data is empty -> **Fallback**.

Note: Other payload types will be supported in the future.

#### C. Change Output

Standard change outputs back to the sender.

## Fee Calculation

The amount of nBTC minted is calculated as follows:

```text
MintedAmount = DepositAmount - NbtcProtocolFee
```

## Redeem UTXO Selection Rating Algorithm

For withdrawal requests, the system selects optimal UTXOs to minimize transaction fees, avoid dust outputs, and maintain efficient key rotation. The ranking algorithm evaluates UTXO combinations based on the following criteria:

1. **Exact matches** (+1,000 points): Combinations that produce zero change output
2. **Dust avoidance** (-200 points): Penalizes change outputs below 10,000 satoshis
3. **Key rotation** (+200 points per UTXO): Prioritizes spending from inactive keys
4. **Input minimization** (-100 points per input): Reduces transaction size and fees

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
3. **Sufficient value**: Total UTXO value must be at least equal to the withdrawal amount. When the total exceeds the withdrawal amount, the difference becomes a change output sent back to the nBTC contract's Bitcoin address, creating a new UTXO that can be used for future withdrawals.

If validation fails, the transaction is aborted with an appropriate error code.
