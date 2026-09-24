#!/usr/bin/env bash
# Runs the benchmarks behind the lesson's "Real runs" fence. Not run by CI:
# ns/op and B/op differ between machines. Run from this folder:
#
#	bash bench.sh
set -u
export GOTOOLCHAIN=local
here=$(cd "$(dirname "$0")" && pwd)
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cp "$here/reflection_costs_bench_test.go" "$dir/"
cd "$dir" || exit 1
go mod init example >/dev/null 2>&1 || exit 1
go version
go test -bench . -benchmem -count 1 -run '^$' .
