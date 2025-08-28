<!-- markdownlint-disable MD041 -->
<!-- markdownlint-disable MD034 -->

![Logo!](assets/logo.png)

# Bitcoin Chain Abstraction on Sui powered by Native

Move packages for Native Bitcoin Chain Abstraction on Sui.
Packages:

- [nBTC](./nBTC) - the synthetic 1-1 Bitcoin, fully permissionless, custodyless, and rightmost trust minimized.
- [nBTC OTC](./nbtc_swap) - simple marketplace to buy nBTC with SUI.
- [Bitcoin Executor](./bitcoin_executor) - trustless Bitcoin execution node on Sui (part of the Trustless Sui Bitcoin Node).

## Deployed objects & packages

- [Alpha Testnet](INTEGRATIONS-testnet-alpha.md)
- [Bitcoin Executor contracts](https://github.com/gonative-cc/sui-native/tree/master/bitcoin_executor#deployed-smart-contracts)

## Contributing

Participating in open source is often a highly collaborative experience. We’re encouraged to create in public view, and we’re incentivized to welcome contributions of all kinds from people around the world.

Check out [contributing repo](https://github.com/gonative-cc/contributig) for our guidelines & policies for how to contribute. Note: we require DCO! Thank you to all those who have contributed!

After cloning the repository, **make sure to run `make setup-hooks`**.

### Requirements

- Sui >= latest
- [Bun](https://bun.com/) >= 1.2 -- NOTE: we use bun rather than Node.js
- `prettier` and `prettier-move` to format the code.

### Development

- use `bun format:move` or `bun format:move-all` to format your Move code.

### Security

Check out [SECURITY.md](./SECURITY.md) for security concerns.
