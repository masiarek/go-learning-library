#!/usr/bin/env bash
# Build cost.go once, then run it RUNS times (default 5) for each number of
# goroutines. Every number it prints varies between runs and machines, which
# is why they are here and not in an answer key.
#
#   bash demo/cost.sh          # from the lesson folder
#   bash demo/cost.sh 10
set -eu
cd "$(dirname "$0")"
runs=${1:-5}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
GOTOOLCHAIN=local go build -o "$dir/cost" cost.go
go version
printf '%10s %13s %15s %17s %21s\n' goroutines 'started in ms' 'stack KiB each' 'from OS KiB each' 'NumGoroutine at Wait'
for n in 10000 100000 1000000; do
    for _ in $(seq "$runs"); do
        "$dir/cost" "$n"
    done
done
