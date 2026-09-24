#!/usr/bin/env bash
# vet's "tests" analyzer checks the names and signatures of Test, Benchmark,
# Fuzz and Example functions. It is one of the analyzers go test runs before
# building the test binary, so these mistakes stop go test as well.
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
	"fmt"
	"testing"
)

// A lowercase letter after Test: not a test, and never run.
func TestonHand(t *testing.T) {
	if OnHand("WH-1") != 4 {
		t.Error("wrong count")
	}
}

func BenchmarkonHand(b *testing.B) {
	for b.Loop() {
		OnHand("WH-1")
	}
}

// OnHand is a function, so it has no method Bad.
func ExampleOnHand_Bad() {
	fmt.Println(OnHand("WH-1"))
	// Output: 4
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go vet'
go vet 2>&1
echo "exit status $?"

say 'go test'
go test 2>&1
echo "exit status $?"

say 'go test -vet=off -v'
go test -vet=off -v 2>&1 | sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/'
echo "exit status ${PIPESTATUS[0]}"
