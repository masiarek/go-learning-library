#!/usr/bin/env bash
# Build tally_go.go and run it N times (default 10). Each line is one run's
# counts: how many of 10,000 selects chose each of two always-ready cases.
#
#   bash demo/tally.sh          # from the lesson folder
#   bash demo/tally.sh 50
set -eu
cd "$(dirname "$0")"
runs=${1:-10}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
GOTOOLCHAIN=local go build -trimpath -o "$dir/tally" tally_go.go
for _ in $(seq "$runs"); do
    "$dir/tally"
done
