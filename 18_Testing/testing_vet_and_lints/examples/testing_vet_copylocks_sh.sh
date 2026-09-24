#!/usr/bin/env bash
# A testing.T holds a sync.RWMutex, so passing one by value copies a lock.
# vet's "copylocks" analyzer reports it; go test does not run that analyzer.
# A t.Errorf on the copy marks the copy failed and, through the parent it
# shares with the real T, the package -- but not the test: the test reports
# PASS and the package FAIL. Without -v the message is not printed at all.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >stock.go <<'GO'
package stock

// OnHand reports the units on hand for a SKU.
func OnHand(sku string) int { return len(sku) }
GO

cat >stock_test.go <<'GO'
package stock

import "testing"

// check takes the T by value: a copy, with its own copy of the lock.
func check(t testing.T, sku string, want int) {
	if got := OnHand(sku); got != want {
		t.Errorf("OnHand(%q) = %d, want %d", sku, got, want)
	}
}

func TestOnHand(t *testing.T) {
	check(*t, "WH-1", 5) // wrong: OnHand("WH-1") is 4
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go vet'
go vet 2>&1
echo "exit status $?"

say 'go test -v'
go test -v 2>&1 | sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/'
echo "exit status ${PIPESTATUS[0]}"
