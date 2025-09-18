#!/usr/bin/env bash

# Usage:
#   run-move.sh [build | test]

OP=${1:-test}

for name in $(ls -1 */Move.toml); do
    d=$(dirname $name)
    echo "==> running" $OP "in" $d
    cd $d
    sui move $OP || exit 1
    cd -
done
