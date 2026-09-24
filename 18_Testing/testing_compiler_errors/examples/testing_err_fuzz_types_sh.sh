#!/usr/bin/env bash
# f.Fuzz accepts a function whose first parameter is *testing.T and whose
# other parameters are of the types the fuzzer knows how to mutate. Anything
# else is reported by vet's tests analyzer, which go test runs before it
# builds the test binary.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >stock_test.go <<'GO'
package stock

import "testing"

// Bin is a shelf position: not a type the fuzzer can generate.
type Bin struct{ Row, Slot int }

func FuzzBin(f *testing.F) {
	f.Fuzz(func(t *testing.T, b Bin) {})
}

func FuzzSKU(f *testing.F) {
	f.Fuzz(func(sku string) {})
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test'
go test 2>&1
echo "exit status $?"
