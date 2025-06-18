# nBTC OTC Buy / Sell

This package provides a basic way for users to buy nBTC using SUI on testnet.

It operates with a fixed price set by the contract admin and requires the admin cap to supply/withdraw and change the price of the nBTC.

## Features

- For Users:
  - `buy_nbtc(vault: &mut Vault, coin: Coin<SUI>, ctx: &mut TxContext): Coin<NBTC>`: Send a SUI `Coin` to the `Vault` object to receive nBTC. Returns the `Coin` to enable `pbt`s.
  - `sell_nbtc(vault: &mut Vault, coin: Coin<NBTC>, ctx: &mut TxContext): Coin<SUI>`: Send a nBTC `Coin` to the `Vault` object to receive SUI. Returns the `Coin` to enable `pbt`s.
- For Admin (Requires `AdminCap`):
  - `add_nbtc_liquidity(vault: &mut Vault, nbtc_coin: Coin<NBTC>, ...)`: Adds the entire `Coin<NBTC>` provided to the vault's liquidity.
  - `add_sui_liquidity(vault: &mut Vault, sui_coin: Coin<SUI>, ...)`: Adds the entire `Coin<SUI>` provided to the vault's liquidity.
  - `set_price(vault: &mut Vault, new_price: u64, ...)`: Sets the price. `new_price` is the standard rate (e.g., `25000` for 25k SUI per 1 nBTC).
  - `withdraw(vault: &mut Vault, ...)`: Withdraws all SUI and nBTC from the vault to the admin address.
  - `set_paused(vault: &mut Vault, pause: bool, ...)`: Stops or resumes the `buy_nbtc` function.

## Example

Below is an example of how to call an already deployed and initialized contract on Sui testnet

```bash
sui client call --package 0x4995e309e990a6a93224153108b26bf79197b234c51db6447bbae10b431c42fb --module nbtc_swap --function buy_nbtc --args 0xf280477ca196a4bced5e1db4cd82fcdd647b55585b1d3838dcd8e1b829d263a4 0x4931a2cae0091c86776c571e1193025c19930aca30a4dc5f802011605eb34039 --gas-budget 100000000
```

- PackageID: `0x4995e309e990a6a93224153108b26bf79197b234c51db6447bbae10b431c42fb`
- Module: `nbtc_swap`
- VaultID: `0xf280477ca196a4bced5e1db4cd82fcdd647b55585b1d3838dcd8e1b829d263a4`

## Documentation

Detailed code documentation

- [nbtc_swap](docs/nbtc_swap.md)

## Deployed packages

- nbtc_swap_v1 (soon to be deprecated):
  - packageID: `0x4995e309e990a6a93224153108b26bf79197b234c51db6447bbae10b431c42fb`
  - vaultID: `0xf280477ca196a4bced5e1db4cd82fcdd647b55585b1d3838dcd8e1b829d263a4`
- nbtc_swap_v2:
  - packageID: `0xac799dd8708c2882fcbe2191cfb27bdc9f7654d997ffaa9b530009349f698f3b`
  - vaultID: `0x148a3a004f19aeea0b5df7ffc82a23935ff6cccca433e8e9c14c0f55595425e8`

## Disclaimer

This is developed only for testing purposes. Use with caution.
