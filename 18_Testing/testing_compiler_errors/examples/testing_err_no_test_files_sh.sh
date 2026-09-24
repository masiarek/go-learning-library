#!/usr/bin/env bash
# A package with no _test.go files: go test reports "[no test files]" with a
# question mark and exits 0. A CI step that only checks the exit status does
# not notice that nothing was tested.
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

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test'
go test 2>&1
echo "exit status $?"

say 'go test ./...'
go test ./... 2>&1
echo "exit status $?"
