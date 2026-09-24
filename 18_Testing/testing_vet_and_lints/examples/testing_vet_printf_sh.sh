#!/usr/bin/env bash
# vet's "printf" analyzer knows that t.Errorf, t.Fatalf and t.Logf take a
# format string, and that t.Error, t.Fatal and t.Log do not. It is in the
# subset go test runs, so a wrong verb fails the build of the test binary.
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

func TestOnHand(t *testing.T) {
	got := OnHand("WH-1")
	if got != 4 {
		t.Errorf("OnHand(%q) = %s, want 4", "WH-1", got)
	}
	t.Logf("checked", got)
	t.Error("OnHand(%q) = %d", "WH-1", got)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test'
go test 2>&1
echo "exit status $?"
