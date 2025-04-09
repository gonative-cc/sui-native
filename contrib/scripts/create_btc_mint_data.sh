#!/bin/bash

NETWORK_ARG="-testnet"       # empty for mainnet, -testnet for testnet, -regtest for regtest
DOCKER_PREFIX=""     # emtpy to run on host eg. docker exec -it bitcoind-node

TX_ID=$1

${DOCKER_PREFIX} bitcoin-cli ${NETWORK_ARG} gettransaction $TX_ID > "$TX_ID.json"

block_hash=$(cat "$TX_ID.json" | jq -r ".blockhash")

${DOCKER_PREFIX} bitcoin-cli ${NETWORK_ARG} getblock $block_hash 1 > "$block_hash.json"

python3 ./create_nbtc_proof.py $block_hash $TX_ID
