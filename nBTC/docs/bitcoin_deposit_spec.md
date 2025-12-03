# nBTC Bitcoin Deposit Transaction Spec

This document outlines the requirements for a Bitcoin transaction to be recognized as a valid nBTC deposit by the smart contract.

## Transaction Overview

To mint `nBTC` user must broadcast a Bitcoin transaction containing:

1.  **Funding Inputs**: Standard Bitcoin inputs.
1.  **Deposit Output**: A transfer to the nBTC DWallet.
1.  **Instruction Output**: An `OP_RETURN` payload specifying the destination address on Sui.
1.  **Change Outputs**: Returning excess funds.

## Inputs

Standard Bitcoin inputs (P2PKH, P2WPKH, P2TR, etc.).

## Outputs Structure & Validation

The nBTC contract parses transaction outputs (from index 0). It applies a **"First Match"** policy for identifying relevant outputs.

### A. Deposit Output (The Payment)

This output defines the amount of `BTC` to be minted in form of `nBTC` on Sui.

- **Script**: Must strictly match the active **nBTC DWallet lock script** (e.g., the specific P2WPKH or P2TR script hash registered in the contract, if the contract only registered one for eg, P2TR, any other scripts destined to this address will be ignored).
- **Amount**: Must be > 0 satoshis.
- **Parsing Rule**: The system scans outputs in order. The **first** output matching the registered script is recorded as the `nBTC` deposit.
- _Warning_: Any subsequent outputs to the same address in the same transaction are ignored.

### B. Instruction Output (OP_RETURN)

This output specifies where the minted nBTC will be sent on the Sui network.

- **Type**: `OP_RETURN`.
- **Parsing Rule**: The system scans outputs in order. The **first** `OP_RETURN` output found is treated as the instruction.
- _Fallback_: If no `OP_RETURN` is present, or if it is malformed, funds are minted to the contract's default **Fallback Address**.

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

### C. Change Output

Standard change outputs back to the sender.

## Fee Calculation

The amount of nBTC minted is calculated as follows:

```text
MintedAmount = DepositAmount - NbtcProtocolFee
