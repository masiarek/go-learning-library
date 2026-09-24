#!/usr/bin/env bash
# Run the lesson's program N times (default 20) and count how many distinct
# outputs appeared. The claim is that AllocsPerRun's whole numbers do not move
# between runs: the answer should be 1.
#
#   bash demo/allocs_twenty_runs.sh          # from the lesson folder
#   bash demo/allocs_twenty_runs.sh 100
set -u
cd "$(dirname "$0")" || exit 1
runs=${1:-20}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

go build -o "$dir/allocs" ../examples/allocsperrun_counts_allocations_go.go || exit 1
for _ in $(seq "$runs"); do
	"$dir/allocs" | md5
done | sort | uniq -c | awk -v runs="$runs" '{ n++ } END { printf "%d distinct output(s) over %d runs\n", n, runs }'
