#!/usr/bin/env bash
# vet's `printf` analyzer knows b.Logf is a printf-style function: a %d verb
# given a string is reported, by `go vet` and by `go test`, which runs the
# printf analyzer before every test build.
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

func BenchmarkJoin(b *testing.B) {
	for b.Loop() {
		strings.Join(fields, ";")
	}
	b.Logf("joined %d fields", "two")
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
