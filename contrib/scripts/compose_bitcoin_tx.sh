#!/bin/bash
set -e

#  "-testnet", "-regtest", "-rpcwallet=mywallet", etc.
BITCOIN_CLI_ARGS="-testnet4"

RECIPIENT_ADDRESS="tb1qe60n447jylrxa96y6pfgy8pq6x9zafu09ky7cq"
AMOUNT_BTC="0.00006200"
OP_RETURN_DATA_HEX="c76280db47f593b58118ac78c257f0bfa5bbfef6be2eff385f4e32a781f76945"

# 1. Create Raw Transaction (Outputs Only)
OUTPUTS="{\"$RECIPIENT_ADDRESS\": $AMOUNT_BTC, \"data\": \"$OP_RETURN_DATA_HEX\"}"
RAW_TX_HEX=$(bitcoin-cli $BITCOIN_CLI_ARGS createrawtransaction "[]" "$OUTPUTS")

# 2. Fund Raw Transaction (Adds Inputs, Fee, Change)
FUNDED_TX_JSON=$(bitcoin-cli $BITCOIN_CLI_ARGS fundrawtransaction "$RAW_TX_HEX")
FUNDED_TX_HEX=$(echo "$FUNDED_TX_JSON" | jq -r '.hex')

# 3. Sign
SIGNED_TX_JSON=$(bitcoin-cli $BITCOIN_CLI_ARGS signrawtransactionwithwallet "$FUNDED_TX_HEX")
SIGNED_TX_HEX=$(echo "$SIGNED_TX_JSON" | jq -r '.hex')

# 4. Broadcast
TXID=$(bitcoin-cli $BITCOIN_CLI_ARGS sendrawtransaction "$SIGNED_TX_HEX")

echo "Transaction Broadcasted."
echo "TXID: $TXID"

exit 0
