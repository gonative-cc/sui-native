#!/bin/bash
set -e
PACKAGE_ID="0x5419f6e223f18a9141e91a42286f2783eee27bf2667422c2100afc7b2296731b"
TREASURY_CAP_ID="0x47336d196275369fb52a200682a865a4bffdc9469d755d418d7e985c376ace35"
LIGHT_CLIENT_ID="0x4f989d395bb13b4913b483016641eb7c9cacfd88d2a1ba91523d0542a52af9e4"

# Bitcoin Transaction Details
BTC_TX_VERSION="0x02000000"
BTC_INPUT_COUNT=1
BTC_SERIALIZED_INPUTS="0x6541bc8d572ae0f7f8ac9b9bca552a46dc4d08f15ae36c77d2c62155280bfdeb0000000000fdffffff"
BTC_OUTPUT_COUNT=3
BTC_SERIALIZED_OUTPUTS="0x3818000000000000160014ce9f3ad7d227c66e9744d052821c20d18a2ea78f7440000000000000160014781b0cd92c0e80a4e750377298088f485b0488440000000000000000226a20c76280db47f593b58118ac78c257f0bfa5bbfef6be2eff385f4e32a781f76945" # FULL Serialized outputs (hex string)
BTC_LOCK_TIME="0x00000000"

MERKLE_PROOF='["0xde226d5af97afd52fe43e537c47f120a93f9fdfb105f138f1474fabbe2981627","0xc47bf897df6339821127e91e1d25fb4a978fce79f7e991a46ae743990f0baaf8","0x233bae6fdbdfba8333d2b669aad199dff0acd6e12c9a9d4418532440617fb0e7","0x1ed089632e4cdd6a59332fb5cde4623fa6b99b1fe75f934094e2bfbadb390903","0xc27f3f65f1a800c402714cb42d9ea88ecbb33a2a582357aaed7ccddd248e4ff7","0x6677179cd73d5a871a50d8c367eab417c2994b0c3b7edd6cecda7214946c51c8","0x684890fec2f023f7dcab4b8a0bcc602e684aaa4a7dbcbeeafb9cf3fa865cc96d","0x8a2dbae03754865f1494962014bcec88d33a1525d3c95831e05a95a1008773b0","0x11675fdff932f17a11efab6b68b1c962dff9fe6a5b48f22f69a07a4ce00fd021","0x597fa1ac0c53ca801614c92d63fd5af9ac79ec06ab3e74d53961c5981961930c","0xdf00775cc7cd94cce99db46fe8803fdc64120119959a3eb417f23f7991c672c6"]'
BTC_BLOCK_HEIGHT=76507
BTC_TX_INDEX_IN_BLOCK=51

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

echo sui client call \
    --package "$PACKAGE_ID" \
    --module "nbtc" \
    --function "mint" \
    --args "${ARGS[@]}" \
    --gas-budget "$GAS_BUDGET"
