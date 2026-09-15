#!/usr/bin/env bash
# Build lost_updates.go (the page-view counter with no mutex), run it N times
# (default 10), and print the total each run reached. The totals are expected
# to differ; that is what this script is for.
#
#   bash demo/tally.sh          # from the lesson folder
#   bash demo/tally.sh 50
set -eu
cd "$(dirname "$0")"
runs=${1:-10}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local
go build -trimpath -o "$dir/lost_updates" lost_updates.go
go version
echo "logical CPUs: $(getconf _NPROCESSORS_ONLN)"
for _ in $(seq "$runs"); do
    "$dir/lost_updates"
done
