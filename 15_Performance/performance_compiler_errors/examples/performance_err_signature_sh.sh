#!/usr/bin/env bash
# A benchmark whose parameter is *testing.T instead of *testing.B. The go
# command refuses before compiling anything, and `go vet` says the same.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >line_test.go <<'GO'
package example

import "testing"

func BenchmarkJoin(b *testing.T) {
	for range 10 {
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

# The message names the file by its absolute path in the temporary directory;
# sed keeps only the file name.
say "go test -bench=. -run='^$'"
go test -bench=. -run='^$' 2>&1 | sed -E 's#^/[^ ]*/line_test\.go#./line_test.go#; s/\t[0-9.]+s$//'
echo "exit status ${PIPESTATUS[0]}"

say 'go vet .'
go vet . 2>&1 | sed -E 's#^/[^ ]*/line_test\.go#./line_test.go#'
echo "exit status ${PIPESTATUS[0]}"
