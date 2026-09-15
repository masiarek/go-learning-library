#!/usr/bin/env bash
# Build arrival_order.go (fan_out_fan_in_go.go without its sort) and run it N
# times (default 300). Prints how many distinct arrival orders the runs produced,
# how many came out in input order, and the most common orders with their counts.
#
#   bash demo/tally.sh          # from the lesson folder
#   bash demo/tally.sh 1000
set -eu
cd "$(dirname "$0")"
runs=${1:-300}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local
go build -trimpath -o "$dir/arrival_order" arrival_order.go
for _ in $(seq "$runs"); do
    "$dir/arrival_order"
done >"$dir/orders"
input='goroutine channel select mutex context pipeline worker semaphore'
echo "input order:              $input"
echo "runs:                     $runs"
echo "distinct arrival orders:  $(sort -u "$dir/orders" | wc -l | tr -d ' ')"
echo "runs in input order:      $(grep -c -x "$input" "$dir/orders" || true)"
echo "most common:"
sort "$dir/orders" | uniq -c | sort -rn | head -5
