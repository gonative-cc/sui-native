#!/bin/bash
set -e

INDEXER_URL="${INDEXER_URL:-http://localhost:8080/regtest/api}"
DEPLOY_INFO="deploy-information.json"

# Load deploy info
if [ ! -f "$DEPLOY_INFO" ]; then
	echo "Error: deploy-information.json not found. Run deploy-nbtc first."
	exit 1
fi

BTC_ADDRESS=$(cat "$DEPLOY_INFO" | grep -o '"btc_address"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
if [ -z "$BTC_ADDRESS" ]; then
	echo "Error: btc_address not found in deploy-information.json"
	exit 1
fi

# Get args
AMOUNT_SAT=${1:-10000}
SUI_RECIPIENT=${2:-""}

if [ -z "$SUI_RECIPIENT" ]; then
	echo "Usage: $0 <amount_sat> <sui_address>"
	exit 1
fi

# Convert sat to BTC
AMOUNT_BTC=$(printf "%.8f" "$(echo "scale=8; $AMOUNT_SAT / 100000000" | bc)")

# Remove 0x prefix and build OP_RETURN
SUI_ADDR_HEX="${SUI_RECIPIENT#0x}"
OP_RETURN_DATA="00${SUI_ADDR_HEX}"

echo "=== BTC Deposit Transaction ==="
echo "dWallet Address: $BTC_ADDRESS"
echo "Amount: $AMOUNT_SAT sat ($AMOUNT_BTC BTC)"
echo "Sui Recipient: $SUI_RECIPIENT"
echo "OP_RETURN: $OP_RETURN_DATA"
echo ""

BITCOIN_CLI=(docker exec esplora-regtest /srv/explorer/bitcoin-27.2/bin/bitcoin-cli -regtest -datadir=/data/bitcoin)

# Load wallet
"${BITCOIN_CLI[@]}" loadwallet "default" >/dev/null 2>&1 || true

# Check for mature UTXOs
MATURE_UTXOS=$("${BITCOIN_CLI[@]}" listunspent 1)

# If no mature UTXOs, generate blocks first
if [ -z "$MATURE_UTXOS" ] || [ "$MATURE_UTXOS" = "[]" ]; then
	echo "No mature UTXOs found. Generating 110 blocks..."
	FUNDING_ADDR=$("${BITCOIN_CLI[@]}" getnewaddress)
	"${BITCOIN_CLI[@]}" generatetoaddress 110 "$FUNDING_ADDR" >/dev/null
	echo "Blocks generated."
	sleep 2
fi

# Get first available UTXO
UTXO=$("${BITCOIN_CLI[@]}" listunspent 1 | jq '.[0]')
UTXO_TXID=$(echo "$UTXO" | jq -r '.txid')
UTXO_VOUT=$(echo "$UTXO" | jq -r '.vout')
UTXO_VALUE=$(echo "$UTXO" | jq -r '.amount * 100000000 | round')
CHANGE_ADDRESS=$(echo "$UTXO" | jq -r '.address')

echo "Using UTXO: $UTXO_TXID:$UTXO_VOUT ($UTXO_VALUE sat)"
echo ""

# Calculate change
FEE=1000
CHANGE_SAT=$(echo "$UTXO_VALUE - $AMOUNT_SAT - $FEE" | bc)

if [ "$(echo "$CHANGE_SAT < 0" | bc)" -eq 1 ]; then
	echo "Error: Not enough funds in UTXO"
	exit 1
fi

# Create raw transaction - outputs: dWallet address + OP_RETURN + change
if [ "$(echo "$CHANGE_SAT > 0" | bc)" -eq 1 ]; then
	CHANGE_BTC=$(printf "%.8f" "$(echo "scale=8; $CHANGE_SAT / 100000000" | bc)")
	RAW_TX=$("${BITCOIN_CLI[@]}" createrawtransaction \
		"[{\"txid\":\"$UTXO_TXID\",\"vout\":$UTXO_VOUT}]" \
		"{\"$BTC_ADDRESS\":$AMOUNT_BTC,\"data\":\"$OP_RETURN_DATA\",\"$CHANGE_ADDRESS\":$CHANGE_BTC}")
else
	RAW_TX=$("${BITCOIN_CLI[@]}" createrawtransaction \
		"[{\"txid\":\"$UTXO_TXID\",\"vout\":$UTXO_VOUT}]" \
		"{\"$BTC_ADDRESS\":$AMOUNT_BTC,\"data\":\"$OP_RETURN_DATA\"}")
fi

echo "Raw transaction created"

# Sign the transaction
SIGNED_TX=$("${BITCOIN_CLI[@]}" signrawtransactionwithwallet "$RAW_TX" | jq -r '.hex')

# Broadcast the transaction
TXID=$("${BITCOIN_CLI[@]}" sendrawtransaction "$SIGNED_TX")

echo ""
echo "=== Transaction Broadcasted ==="
echo "TXID: $TXID"

# Generate 5 blocks to confirm
echo ""
echo "Generating 5 blocks to confirm..."
"${BITCOIN_CLI[@]}" generatetoaddress 5 "$CHANGE_ADDRESS" >/dev/null

# Wait for indexer
sleep 2

# Get block height
HEIGHT=$(curl -s "${INDEXER_URL}/tx/${TXID}/status" | jq -r '.block_height // empty')

if [ -z "$HEIGHT" ]; then
	echo "Error: Could not get block height from indexer"
	exit 1
fi

# Get block hash
BLOCK_HASH=$(curl -s "${INDEXER_URL}/block-height/${HEIGHT}")

# Get tx index in block
TXIDS=$(curl -s "${INDEXER_URL}/block/${BLOCK_HASH}/txids")
TX_INDEX=$(echo "$TXIDS" | bun -e "const txids=JSON.parse(require('fs').readFileSync(0,'utf8')); const idx=txids.indexOf('$TXID'); console.log(idx >= 0 ? idx : 0)")

echo ""
echo "=== Confirmation Info ==="
echo "TXID: $TXID"
echo "Block Height: $HEIGHT"
echo "TX Index: $TX_INDEX"
echo ""
echo "Outputs:"
echo "  [0] $BTC_ADDRESS (dWallet) -> $AMOUNT_SAT sat"
echo "  [1] OP_RETURN: $OP_RETURN_DATA"
echo ""
echo "Now run:"
echo "  bun run scripts/mint.ts mint $TXID $HEIGHT $TX_INDEX"
