![Logo!](assets/logo.png)

# Bitcoin Chain Abstraction on Sui powered by Native

Move packages for Native Bitcoin Chain Abstraction on Sui.
Packages:

- [nBTC](./nBTC) - the synthetic 1-1 Bitcoin, fully permissionless, custodyless, and rightmost trust minimized.
- [nBTC OTC] - simple marketplace to buy nBTC with SUI.
- [Bitcoin Executor](./bitcoin_executor) - trustless Bitcoin execution node on Sui (part of the Trustless Sui Bitcoin Node).

## Deployed objects & packages

### Alpha release (testnet)

`nBTC` (Coin), version: `nBTC/v0.1.0`

- Package ID: `0x5419f6e223f18a9141e91a42286f2783eee27bf2667422c2100afc7b2296731b`
- Instance: `0xc9df2d40e6b03c967af372c7f098ec663e06a21e28dc2927e6b91f441d65fbd1`
- Treasury Cap ID: `0x47336d196275369fb52a200682a865a4bffdc9469d755d418d7e985c376ace35`
- uses [Bitcoin Light Client](https://github.com/gonative-cc/move-bitcoin-spv): `0x4f989d395bb13b4913b483016641eb7c9cacfd88d2a1ba91523d0542a52af9e4`

BTC P2WPKH deposit address for `nBTC` minting: `tb1qe60n447jylrxa96y6pfgy8pq6x9zafu09ky7cq` on **Bitcoin v4 testnet**.

## Contributing

Participating in open source is often a highly collaborative experience. We’re encouraged to create in public view, and we’re incentivized to welcome contributions of all kinds from people around the world.

Check out [contributing repo](https://github.com/gonative-cc/contributig) for our guidelines & policies for how to contribute. Note: we require DCO! Thank you to all those who have contributed!

After cloning the repository, make sure to run `make setup-hooks`.

### Security

Check out [SECURITY.md](./SECURITY.md) for security concerns.
