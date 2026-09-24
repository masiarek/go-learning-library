#!/usr/bin/env bash
# A test in the external test package, stock_test, is a client of the
# package: it sees only what is exported. Reaching for an unexported
# function, or misspelling an exported one, is a compile error.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >stock.go <<'GO'
package stock

func onHand(sku string) int { return len(sku) }

// OnHand reports the units on hand for a SKU.
func OnHand(sku string) int { return onHand(sku) }
GO

cat >stock_test.go <<'GO'
package stock_test

import (
	"testing"

	"example"
)

func TestOnHand(t *testing.T) {
	if stock.onHand("WH-1") != 4 {
		t.Error("wrong count")
	}
	if stock.Onhand("WH-1") != 4 {
		t.Error("wrong count")
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test'
go test 2>&1
echo "exit status $?"
