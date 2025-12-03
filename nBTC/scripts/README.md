# nBTC

We have a few scripts which is help deploy nBTC and interact with nbtc core functions.

## Setup .env

```bash
MNEMONIC= sui mnemonic, we use this for sign tx
NBTC=nbtc contract object id
DWALLET_ID= dwallet id of entry point of dwallet
ADMINCAP=admin cap of nbtc
PACKAGE_ID=nbtc package id
```

## Initialization

Publish the package using sui-cli, and update the .env file.

```bash
sui client publish
```

Create a new dwallet, add it to the nBTC object and activate it

```bash
bun run scripts/index.ts init_dwallet
```

<!-- ## TODO: Mint nbtc -->

<!-- ## TODO: Create redeem request -->

## Request signature from ika for the inputs in redeem transaction

```bash
bun run index.ts request_signature <redeem_id> <input_idx>
```

The function above will return the `signature_id`

## Validate signature for input

Verify the signature Ika created, if the signature is valid we will mark that input as `signed`.

```bash
bun run index.ts verify <redeem_id> <input_idx> <sign_id>
```
