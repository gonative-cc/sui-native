#!/usr/bin/bash

for name in "bitcoin_executor" "btc_parser" "nBTC" "nbtc_swap"; do
    echo testing $name
    cd $name && sui move build && sui move test && cd .. || exit 1
done
