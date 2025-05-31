# Bitcoin Execution Layer on Sui - Demo Guide

This guide show the steps to run a demonstration of the Bitcoin Executor, which operates as a Move smart contract on the Sui blockchain. The demo will show the execution of Bitcoin blocks and the management of the UTXO set on-chain.

## Prerequisites

1.  Bitcoin Core (`bitcoind`):

    - Installed and running in `regtest` mode.
    - Ensure you can interact with it via `bitcoin-cli -regtest`.
    - For a clean state, you might want to stop `bitcoind`, remove your `regtest` data directory (e.g., `rm -rf ~/.bitcoin/regtest`), and restart `bitcoind -regtest -daemon`.

    As an alternative you can use docker setup from `relayer/contrib`

2.  Relayer Scripts https://github.com/gonative-cc/relayer

    - You will need the `btc_executor.sh` and `submit_blocks.sh` scripts from `demo_scripts` directory. (Or you can perform these actions manually).

3.  Sui Development Environment:
    - Sui client installed and configured to connect to a Sui network.
    - A Sui address with sufficient SUI gas tokens for deploying and interacting with the smart contract.

## Demo Steps

### Step 1: Deploy the Bitcoin Execution Layer Contract

First, you need to deploy the Move package containing the `bitcoin_executor` module to your target Sui network.

1.  Navigate to your Move package directory.
2.  Publish the contract using the Sui client:

    ```bash
    sui client publish
    ```

3.  Save Package ID and State Object ID:

    - After successful publication, the output will include a "Created Objects" section.
    - Note down the _Package ID_ and _State Object ID_.
      You will need these IDs for `btc_executor.sh` and `submit_blocks.sh` scripts.

### Step 2: Prepare Bitcoin Regtest Environment

This step involves creating wallets, generating addresses, and mining blocks on your local Bitcoin `regtest` node.

- Option A: Using `btc_executor.sh` script:

  - Navigate to your `relayer/demo_scripts/` directory.
  - Ensure the `btc_executor.sh` script is executable (`chmod +x btc_executor.sh`).
  - Run the script:

    ```bash
    ./btc_executor.sh
    ```

  - This script should:
    1.  Create/load "alice" and "bob" wallets.
    2.  Generate P2WPKH addresses for Alice and Bob.
    3.  Mine 200 blocks to Alice's address (maturing coinbase outputs and ensuring SegWit is active).
    4.  Create a SegWit transaction where Alice sends 1 BTC to Bob.
    5.  Mine 1 more block (total 201 blocks from genesis, block index 200) to confirm this transaction.
    6.  Output the raw hex of that transaction.

- Option B: Manual Steps
  Check the bitcoin-cli docs for it.

### Step 3: Submit Bitcoin Blocks to the Sui Execution Layer

Now, we will send the hex data of these Bitcoin blocks

- Option A: Using `submit_blocks.sh` script:

  - This script will loop from block 0 to 201, fetch each block's raw hex, and perform the `sui client call`.
  - _Important:_ You will need to edit `submit_blocks.sh` to set `PACKAGE_ID` and `STATE_OBJECT_ID` to the values you obtained in Step 1.
  - Ensure the `submit_blocks.sh` script is executable (`chmod +x submit_blocks.sh`).
  - Run the script:

    ```bash
    ./submit_blocks.sh

    ```

  - Observe the logs from the script and potentially from your Sui node/Move contract.

- Option B: Manual Submission (Example for one block):
  Check the bitcoin-cli and sui-client docs for it.
