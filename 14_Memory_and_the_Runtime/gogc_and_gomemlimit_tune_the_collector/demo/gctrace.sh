#!/usr/bin/env bash
# Build a program that churns through 256 MiB of garbage, and run it with
# GODEBUG=gctrace=1 under three settings: the defaults, GOGC=25, and GOGC=off
# with a 32 MiB memory limit. The trace lines carry timings and heap sizes
# that differ between runs, which is why this is a demo and not an example.
#
#   bash demo/gctrace.sh          # from the lesson folder
set -u
cd "$(dirname "$0")" || exit 1
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/churn.go" <<'GO'
package main

var slab []byte

func main() {
	for range 256 {
		slab = make([]byte, 1<<20)
	}
}
GO
(cd "$dir" && go build churn.go) || exit 1

for setting in "" "GOGC=25" "GOGC=off GOMEMLIMIT=32MiB"; do
	echo "== ${setting:-defaults}: the first three gctrace lines, then the count =="
	env $setting GODEBUG=gctrace=1 "$dir/churn" >"$dir/trace.txt" 2>&1
	head -n 3 "$dir/trace.txt"
	echo "collections: $(grep -c '^gc ' "$dir/trace.txt")"
	echo
done
