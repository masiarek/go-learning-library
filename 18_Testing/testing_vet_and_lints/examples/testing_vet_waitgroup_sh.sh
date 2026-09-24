#!/usr/bin/env bash
# vet's "waitgroup" analyzer, new in Go 1.25, reports wg.Add called inside
# the goroutine it is meant to count: by then Wait may already have
# returned. It is not in the subset go test runs, and the test passes on a
# run in which the Add happens to come first.
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

import (
	"sync"
	"testing"
)

func TestTotalOnHand(t *testing.T) {
	var wg sync.WaitGroup
	var mu sync.Mutex
	total := 0
	for _, sku := range []string{"WH-1", "WH-22"} {
		go func() {
			wg.Add(1) // too late: Wait may have returned already
			defer wg.Done()
			mu.Lock()
			total += OnHand(sku)
			mu.Unlock()
		}()
	}
	wg.Wait()
	if total != 9 {
		t.Errorf("total = %d, want 9", total)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go vet'
go vet 2>&1
echo "exit status $?"
