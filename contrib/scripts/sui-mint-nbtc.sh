#!/bin/bash
# Constructs Bitcoin payment proof and sends Sui transaction nBTC mint transaction

if [ -z "$1" ]; then
  echo "Usage: $0 <bitcoin_nbtc_tx_id>"
  exit 1
fi

set -e

PACKAGE_ID="0x5419f6e223f18a9141e91a42286f2783eee27bf2667422c2100afc7b2296731b"
TREASURY_CAP_ID="0x47336d196275369fb52a200682a865a4bffdc9469d755d418d7e985c376ace35"
LIGHT_CLIENT_ID="0x4f989d395bb13b4913b483016641eb7c9cacfd88d2a1ba91523d0542a52af9e4"

TX_ID="$1"

JSON_DATA=$(./create_btc_mint_data.sh "$TX_ID")

# extract bitcoin tx details
BTC_TX_VERSION=$(echo "$JSON_DATA" | jq -r '.version')
BTC_INPUT_COUNT=$(echo "$JSON_DATA" | jq -r '.input_count')
BTC_SERIALIZED_INPUTS=$(echo "$JSON_DATA" | jq -r '.inputs')
BTC_OUTPUT_COUNT=$(echo "$JSON_DATA" | jq -r '.output_count')
BTC_SERIALIZED_OUTPUTS=$(echo "$JSON_DATA" | jq -r '.outputs')
BTC_LOCK_TIME=$(echo "$JSON_DATA" | jq -r '.lock_time')
MERKLE_PROOF=$(echo "$JSON_DATA" | jq -c '.proof')
BTC_BLOCK_HEIGHT=$(echo "$JSON_DATA" | jq -r '.height')
BTC_TX_INDEX_IN_BLOCK=$(echo "$JSON_DATA" | jq -r '.tx_index')

GAS_BUDGET=100000000
ARGS=(
    "$TREASURY_CAP_ID"
    "$LIGHT_CLIENT_ID"
    "$BTC_TX_VERSION"
    "$BTC_INPUT_COUNT"
    "$BTC_SERIALIZED_INPUTS"
    "$BTC_OUTPUT_COUNT"
    "$BTC_SERIALIZED_OUTPUTS"
    "$BTC_LOCK_TIME"
    "$MERKLE_PROOF"
    "$BTC_BLOCK_HEIGHT"
    "$BTC_TX_INDEX_IN_BLOCK"
)

sui client call \
  --package "$PACKAGE_ID" \
  --module "nbtc" \
  --function "mint" \
  --args "${ARGS[@]}" \
  --gas-budget "$GAS_BUDGET"
