#!/usr/bin/env bash
# -run and -skip take a regular expression per level of the test name,
# split on "/": -run TestParse matches the top-level tests whose names
# contain TestParse, -run '/empty' matches subtests called empty under any
# test, and -skip '/empty' removes them. A -run that matches nothing is a
# warning, not a failure: go test still exits 0.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >stock_test.go <<'GO'
package stock

import "testing"

func TestParseQuantity(t *testing.T) {
	for _, name := range []string{"crates", "empty", "negative"} {
		t.Run(name, func(t *testing.T) {})
	}
}

func TestParseUnit(t *testing.T) {
	for _, name := range []string{"plural", "empty"} {
		t.Run(name, func(t *testing.T) {})
	}
}

func TestTotal(t *testing.T) {}
GO

say() { printf '$ %s\n' "$*"; }

# Only the "=== RUN" lines: which tests ran.
ran() {
	grep -E '^(=== RUN|testing:|ok|FAIL|PASS)' test.txt | sed -E 's/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/'
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v -run TestParse'
go test -v -run TestParse >test.txt 2>&1
status=$?
ran
echo "exit status $status"

say "go test -v -run '/empty'"
go test -v -run '/empty' >test.txt 2>&1
status=$?
ran
echo "exit status $status"

say "go test -v -run 'TestParseQuantity/^(crates|negative)$'"
go test -v -run 'TestParseQuantity/^(crates|negative)$' >test.txt 2>&1
status=$?
ran
echo "exit status $status"

say "go test -v -skip '/empty'"
go test -v -skip '/empty' >test.txt 2>&1
status=$?
ran
echo "exit status $status"

say "go test -v -skip 'empty'     # no slash: matched against the top level only"
go test -v -skip 'empty' >test.txt 2>&1
status=$?
ran
echo "exit status $status"

say 'go test -run TestInvoice'
go test -run TestInvoice >test.txt 2>&1
status=$?
ran
echo "exit status $status"
