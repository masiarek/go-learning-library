#!/usr/bin/env bash
# vet's "testinggoroutine" analyzer reports t.Fatal, t.FailNow and t.Skip
# called from a goroutine the test started with a go statement. It is not in
# the subset go test runs, so go test passes the test; and a goroutine
# started through wg.Go is not reported at all.
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

func TestOnHandWithGo(t *testing.T) {
	var wg sync.WaitGroup
	for _, sku := range []string{"WH-1", "WH-22"} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if OnHand(sku) == 0 {
				t.Fatalf("OnHand(%q) = 0", sku)
			}
		}()
	}
	wg.Wait()
}

func TestOnHandWithWgGo(t *testing.T) {
	var wg sync.WaitGroup
	for _, sku := range []string{"WH-1", "WH-22"} {
		wg.Go(func() {
			if OnHand(sku) == 0 {
				t.Fatalf("OnHand(%q) = 0", sku)
			}
		})
	}
	wg.Wait()
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go vet'
go vet 2>&1
echo "exit status $?"

say 'go test'
go test 2>&1 | sed -E 's/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/'
echo "exit status ${PIPESTATUS[0]}"
