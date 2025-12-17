# Sui Native TypeScript SDK

This directory contains the TypeScript SDK generated from the Move contracts in the sui-native project. It provides type-safe bindings to interact with the Bitcoin-related smart contracts on Sui.

## Structure

- `nBTC/` - nBTC package directory
  - `src/` - Source directory for the nBTC SDK
    - `index.ts` - Main entry point that exports all generated modules
    - `types.ts` - Common TypeScript types used across the SDK
  - `generated/` - Auto-generated TypeScript bindings from Move contracts
    - `utils/` - Utility functions for interacting with Sui
    - `nbtc/` - TypeScript bindings for the nBTC Move package

## Generating TypeScript Code

To regenerate the TypeScript bindings after making changes to the Move contracts:

```bash
# From the repository root
bun run generate-ts
```

This command uses `@mysten/codegen` to parse the Move contracts and generate corresponding TypeScript code. The generated files are placed in `nBTC/generated/`.

## Configuration

The code generation is configured in `sui-codegen.config.ts`:

```typescript
import type { SuiCodegenConfig } from "@mysten/codegen";

const config: SuiCodegenConfig = {
  output: "./nBTC/generated",
  generateSummaries: true,
  prune: true,
  packages: [
    {
      package: "@local-pkg/nbtc",
      path: "../nBTC",
    },
    // Other packages can be added here
  ],
};

export default config;
```

## Using the SDK

Import the generated modules from your application:

```typescript
import { nBTCContractModule, UtilsModule } from "./sdk/nBTC/src";
```

Each generated module provides functions to interact with the corresponding Move package, including:

- Transaction builders
- Type definitions for Move structs
- Helper functions for serialization/deserialization
- Constants and enumerations

## Important Notes

- The generated TypeScript code requires `verbatimModuleSyntax` to be disabled in the TypeScript configuration (see the root `tsconfig.json`)
- Regenerated code will overwrite existing files in `nBTC/generated/`
- Only edit files in `nBTC/src/` that are not in the `generated/` directory

## Dependencies

The SDK depends on:

- `@mysten/sui` - Sui TypeScript SDK
- `@mysten/codegen` - Code generation tool for Move contracts
- Other dependencies as specified in the root `package.json`
