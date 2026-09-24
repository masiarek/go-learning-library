#!/usr/bin/env bash
# A panic in one test takes the whole test binary down: the tests after it
# never run, go test prints the test binary's "exit status 2", and exits 1
# itself. The panic's goroutine trace holds paths and addresses, so only the
# lines that do not vary are kept.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >stock_test.go <<'GO'
package stock

import "testing"

func TestBins(t *testing.T) {
	var bins map[string]int // nil: never made
	bins["WH-1"] = 12
}

func TestPallets(t *testing.T) {
	t.Log("never reached")
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v'
go test -v >test.txt 2>&1
status=$?
sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt | grep -E '^(=== |--- |panic:|FAIL|ok|PASS|exit status)'
echo "exit status $status"
