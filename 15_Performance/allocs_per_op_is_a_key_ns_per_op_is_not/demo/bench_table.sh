#!/usr/bin/env bash
# The full `go test -bench` table for the benchmarks in
# examples/allocs_per_op_is_a_key_sh.sh: the default one second per benchmark,
# -count=5, ns/op and all. This is the part of the output the key leaves out,
# because it changes from run to run and from machine to machine.
#
#   bash demo/bench_table.sh          # from the lesson folder
#   bash demo/bench_table.sh 10       # -count=10
set -u
cd "$(dirname "$0")" || exit 1
count=${1:-5}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

# The test file is the one the example script writes, so the two cannot drift.
sed -n "/^cat >line_test.go <<'GO'\$/,/^GO\$/p" ../examples/allocs_per_op_is_a_key_sh.sh | sed '1d;$d' >"$dir/line_test.go"
cd "$dir" && go mod init example >/dev/null 2>&1 || exit 1
echo "\$ go test -bench=. -benchmem -count=$count -run='^\$'"
go test -bench=. -benchmem -count="$count" -run='^$'
