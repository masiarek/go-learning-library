#!/usr/bin/env bash
# A Test function with the wrong signature. go test itself refuses it while
# it loads the package -- before vet, before the compiler -- and prints the
# file's absolute path, which this script shortens to ./ .
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

func TestOnHand(t testing.T) {
	if OnHand("WH-1") != 4 {
		t.Error("wrong count")
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test'
go test 2>&1 | sed -E 's#^/.*/(stock_test\.go):#./\1:#'
echo "exit status ${PIPESTATUS[0]}"

say 'go vet'
go vet 2>&1 | sed -E 's#^/.*/(stock_test\.go):#./\1:#'
echo "exit status ${PIPESTATUS[0]}"
