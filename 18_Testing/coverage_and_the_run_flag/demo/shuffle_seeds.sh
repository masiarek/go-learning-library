#!/usr/bin/env bash
# Run the tests from examples/coverage_shuffle_and_short_sh.sh N times
# (default 5) with -shuffle=on, and print the seed and the order each run
# used. The seed is the time in nanoseconds, so no two runs agree -- which
# is why the example uses -shuffle=1 and this is a demo.
#
#   bash demo/shuffle_seeds.sh          # from the lesson folder
#   bash demo/shuffle_seeds.sh 20
set -u
cd "$(dirname "$0")" || exit 1
runs=${1:-5}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

sed -n "/^cat >stock_test.go <<'GO'\$/,/^GO\$/p" ../examples/coverage_shuffle_and_short_sh.sh | sed '1d;$d' >"$dir/stock_test.go"
cd "$dir" && go mod init example 2>/dev/null

for _ in $(seq "$runs"); do
	go test -v -shuffle=on -run 'Crates|Pallets|Bins' 2>&1 | awk '/^-test.shuffle/ { seed = $2 } /^=== RUN/ { order = order " " $3 } END { print seed ":" order }'
done
