#!/bin/bash

TX_ID=$1

docker exec -it bitcoind-node bitcoin-cli gettransaction $TX_ID > "$TX_ID.json"

block_hash=$(cat "$TX_ID.json" | jq -r ".blockhash")

docker exec -it bitcoind-node bitcoin-cli getblock $block_hash 1 > "$block_hash.json"

python ./create_nbtc_proof.py $block_hash $TX_ID
