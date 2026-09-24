#!/usr/bin/env bash
# -shuffle=on runs the tests in a random order and prints the seed it used,
# which changes every run; -shuffle=<seed> repeats one order, so a fixed
# seed is what a key can hold. testing.Short reports the -short flag, and a
# test that calls t.Skip under it is reported as SKIP, not PASS.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >stock_test.go <<'GO'
package stock

import "testing"

func TestCrates(t *testing.T)  {}
func TestPallets(t *testing.T) {}
func TestBins(t *testing.T)    {}

func TestFullImport(t *testing.T) {
	if testing.Short() {
		t.Skip("the full import takes minutes; skipped under -short")
	}
	t.Log("importing every delivery note")
}
GO

say() { printf '$ %s\n' "$*"; }

tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say "go test -v -shuffle=1 -run 'Crates|Pallets|Bins'"
go test -v -shuffle=1 -run 'Crates|Pallets|Bins' >test.txt 2>&1
status=$?
tidy | grep -E '^(-test.shuffle|=== RUN|ok|FAIL)'
echo "exit status $status"

say "go test -v -shuffle=7 -run 'Crates|Pallets|Bins'"
go test -v -shuffle=7 -run 'Crates|Pallets|Bins' >test.txt 2>&1
status=$?
tidy | grep -E '^(-test.shuffle|=== RUN|ok|FAIL)'
echo "exit status $status"

say 'go test -v -run TestFullImport'
go test -v -run TestFullImport >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test -v -short -run TestFullImport'
go test -v -short -run TestFullImport >test.txt 2>&1
status=$?
tidy
echo "exit status $status"
