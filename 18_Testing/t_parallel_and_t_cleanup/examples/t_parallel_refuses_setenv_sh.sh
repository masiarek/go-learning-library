#!/usr/bin/env bash
# t.Setenv sets a process-wide variable and restores it in a Cleanup, which
# only makes sense while no other test runs: a test that calls both t.Setenv
# and t.Parallel panics, in either order. The panic's goroutine trace holds
# paths and addresses, so only its first line is printed.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local
unset WAREHOUSE_REGION

cat >region_test.go <<'GO'
package warehouse

import (
	"os"
	"testing"
)

func TestRegion(t *testing.T) {
	t.Setenv("WAREHOUSE_REGION", "north")
	t.Log("WAREHOUSE_REGION =", os.Getenv("WAREHOUSE_REGION"))
}

func TestRegionAfter(t *testing.T) {
	t.Logf("after TestRegion, WAREHOUSE_REGION = %q", os.Getenv("WAREHOUSE_REGION"))
}

func TestRegionParallel(t *testing.T) {
	t.Parallel()
	t.Setenv("WAREHOUSE_REGION", "north")
}
GO

say() { printf '$ %s\n' "$*"; }

tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say "go test -v -run 'TestRegion$|TestRegionAfter'"
go test -v -run 'TestRegion$|TestRegionAfter' >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test -v -run TestRegionParallel'
go test -v -run TestRegionParallel >test.txt 2>&1
status=$?
tidy | grep -E '^(=== |--- |panic:|FAIL|exit status)'
echo "exit status $status"
