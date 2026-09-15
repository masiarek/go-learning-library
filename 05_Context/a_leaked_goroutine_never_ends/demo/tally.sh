#!/usr/bin/env bash
# Build leak_race.go, run it N times (default 20), and print how many of its
# 1000 goroutines each run leaked, smallest first, ten to a line.
#
#   bash demo/tally.sh          # from the lesson folder
#   bash demo/tally.sh 100
set -eu
cd "$(dirname "$0")"
runs=${1:-20}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
GOTOOLCHAIN=local go build -o "$dir/leak_race" leak_race.go
for _ in $(seq "$runs"); do
    "$dir/leak_race"
done | sort -n | paste -d ' ' - - - - - - - - - -
