#!/usr/bin/env bash
# vet's `tests` analyzer: a benchmark named Benchmarkjoin is not a benchmark
# at all -- the letter after "Benchmark" must be upper case -- so `go test`
# would silently skip it. vet reports the name, and because `go test` runs
# this analyzer itself, the test build fails too.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >line_test.go <<'GO'
package example

import (
	"strings"
	"testing"
)

var fields = []string{"customer=acme-industries", "item=steel-bracket-40mm"}

func Benchmarkjoin(b *testing.B) {
	for b.Loop() {
		strings.Join(fields, ";")
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet .'
go vet . 2>&1
echo "exit status $?"

say "go test -bench=. -run='^$'"
go test -bench=. -run='^$' 2>&1 | sed -E 's/\t[0-9.]+s$//'
echo "exit status ${PIPESTATUS[0]}"

say 'sed -i.bak s/Benchmarkjoin/BenchmarkJoin/ line_test.go && go vet .'
sed -i.bak 's/Benchmarkjoin/BenchmarkJoin/' line_test.go && go vet . 2>&1
echo "exit status $?"
