# Gemini Project Overview: sui-native

## Project Overview

This repository, `sui-native`, is a collection of Move packages for Bitcoin Chain Abstraction, and other related Native projects, on the Sui blockchain. It enables the use of Bitcoin-related functionalities and assets within the Sui ecosystem.

Key Move packages:

- `bitcoin_lib/`: A Move library that provides various utilities and data structures for working with Bitcoin within the Sui environment. Core Bitcoin primitives (transactions, headers, crypto)
- `bitcoin_spv/`: Simplified Payment Verification (SPV) light client
- `bitcoin_executor/`: A trustless Bitcoin execution node on Sui, which is part of the Trustless Sui Bitcoin Node. This allows for the execution and verification of Bitcoin transactions on the Sui network.
- `nBTC/`: A Move package that implements a synthetic, 1:1 backed representation of Bitcoin on Sui. It is designed to be permissionless, custodyless, and trust-minimized. Provides nBTC coin implementation with minting/burning logic.
- `nbtc_swap/`: A simple marketplace, built with Move, to facilitate the swapping of nBTC with Sui.

The project is built using the Move programming language for the smart contracts and uses `bun` for managing JavaScript/TypeScript dependencies and running scripts.

## Building and Running

### Move Package Commands (per package)

Run these from within each package directory (e.g., `cd nBTC && make test`):

- **Build**: `make build` or `sui move build`
- **Test**: `make test` or `sui move test --gas-limit 5000000`
- **Test with coverage**: `make test-coverage` or `sui move test --gas-limit 5000000 --coverage`
- **Lint**: `make lint` (lints modified files) or `make lint-all` (lints all)
- **Lint fix**: `make lint-fix-all` (fixes markdown, formats Move)
- **Generate docs**: `make gen-docs` (builds and copies docs to docs/)

### Root-level Commands

Run from repository root:

- **Build all Move packages**: `make build-move-all`
- **Test all Move packages**: `make test-move-all`
- **Format all Move files**: `make format-move-all`
- **Add license headers**: `make add-license` (adds SPDX to .move files)
- **Setup git hooks**: `make setup-hooks` (installs pre-commit hooks and prettier)

### JavaScript/TypeScript Commands

Run from repository root:

- **Install dependencies**: `bun install`
- **Type check**: `bun run typecheck` or `tsc --noEmit`
- **Format all**: `bun run format:all`
- **Format Move files**: `bun run format:move-all`
- **Test**: `bun run test`
- **Generate TypeScript from Move**: `bun run generate-ts` (generates TypeScript SDK from Move contracts in sdk/src/generated)

Note: The TypeScript generation creates bindings that interact with Move contracts. After running `generate-ts`, the generated files will be in `sdk/src/generated/`. The current TypeScript configuration has `verbatimModuleSyntax` disabled to accommodate the generated code.

### CI Commands

- Move packages: `bash ./contrib/run-move-tests.sh test` (builds and tests all)
- JS: `bun ci`, then `bun run lint`, `bun run typecheck`, `bun run test`

## Code Organization and Patterns

- **Formatting**: The project uses `prettier` and `prettier-move` for code formatting. All Move code should be formatted before committing.
- **Licensing**: The project uses the MPL-2.0 license. There is a command `make add-license` to add the license header to all source files.
- **Git Hooks**: The project uses git hooks to enforce conventions. It is important to run `make setup-hooks` after cloning the repository.
- **Dependencies**: The project uses `bun` to manage JavaScript/TypeScript dependencies.

### File Structure

- Each Move module is in its own file (e.g., `nbtc.move`, `light_client.move`)
- Test modules are separate files with `_tests` suffix (e.g., `light_client_tests.move`)
- Documentation is generated into `docs/` directories
- SDK generated TypeScript code is in `sdk/src/generated/`:
  - `utils/`: Common utilities for interacting with Sui
  - `nbtc/`: TypeScript bindings for the nBTC Move package
  - Each Move package gets its own directory with generated TypeScript bindings

### Module Organization

- Modules use `module package_name::module_name;` syntax
- Imports follow patterns like `use sui::table::{Self, Table};`
- Custom imports use `use bitcoin_lib::header::BlockHeader;`

### Naming Conventions

- **Modules**: snake_case (e.g., `light_client`, `nbtc`)
- **Functions**: snake_case (e.g., `new_light_client`, `verify_payment`)
- **Structs**: PascalCase (e.g., `LightClient`, `Transaction`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `VERSION`, `EInvalidDepositKey`)
- **Error constants**: Start with `E` (e.g., `EInvalidDepositKey`)

### Move Testing

- Unit tests use `#[test]` functions
- Integration tests use `sui::test_scenario` for multi-transaction flows
- Test gas limits: `--gas-limit 5000000` (required for complex tests)
- Test-only modules with `#[test_only]` attribute
- Assertions: `std::unit_test::assert_eq` and `assert_ref_eq`
- Test helpers: Separate modules for shared test utilities

### JavaScript Testing

- Uses Bun as test runner
- TypeScript with `tsc --noEmit` for type checking

## Important Gotchas

### Move Language Specifics

- Gas limits are critical - tests may fail without `--gas-limit 5000000`
- Shared objects must be created in `init` or transferred properly
- Table operations require careful key management
- Error constants are vectors of bytes, not strings
- Function visibility: `public` for external calls, `fun` for internal

### Repository Specific

- Pre-commit hooks enforce formatting (setup with `make setup-hooks`)
- License headers are automatically added with `make add-license`
- Documentation is generated and copied to `docs/` directories
- Prettier-move is used for Move code formatting (config in `.prettier-move.json`)
- Markdown linting is enforced on changed files

### Development Workflow

- Run `make build-move-all` and `make test-move-all` before commits
- Use `make lint-git` for pre-commit checks
- Format code with `make format-move-all` before pushing
- CI checks formatting and tests on PRs

### Dependencies

- Sui CLI required for Move operations
- Bun for JavaScript/TypeScript tooling
- Prettier with Move plugin for formatting
