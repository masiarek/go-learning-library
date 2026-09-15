#!/usr/bin/env bash
# Build cost.go once, run it RUNS times (default 200) with 10,000 goroutines,
# and tally what runtime.NumGoroutine said the moment Wait returned. Wait
# promises that every function has returned, not that every goroutine has
# gone -- which is why the lesson's example waits for the count itself.
#
#   bash demo/at_wait.sh          # from the lesson folder
#   bash demo/at_wait.sh 1000
set -eu
cd "$(dirname "$0")"
runs=${1:-200}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
GOTOOLCHAIN=local go build -o "$dir/cost" cost.go
go version
echo "runs  NumGoroutine the moment Wait returned"
for _ in $(seq "$runs"); do
    "$dir/cost" 10000 | awk '{ print $5 }'
done | sort -n | uniq -c
