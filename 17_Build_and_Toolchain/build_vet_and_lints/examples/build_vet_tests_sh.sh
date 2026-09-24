#!/usr/bin/env bash
# The tests analyzer: a Test whose name continues in lowercase is not a
# test, an Example that names nothing in the package or a suffix that is not
# a method, and an Example with parameters. go test runs this analyzer too,
# so the package fails before any test runs.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1
mkdir orders
cat >orders/orders.go <<'GO'
package orders

type Invoice struct{ Total int }

func Count() int { return 3 }
GO

cat >orders/orders_test.go <<'GO'
package orders

import "testing"

func Testcount(t *testing.T) {}

func ExampleNoSuch() {}

func ExampleInvoice_Pay() {}

func ExampleCount(n int) {}
GO

say 'go vet ./orders'
go vet ./orders 2>&1
echo "exit status $?"
say 'go test ./orders'
go test ./orders 2>&1 | sed -E 's/\t[0-9.]+s$//'
echo "exit status ${PIPESTATUS[0]}"

cat >orders/orders_test.go <<'GO'
package orders

import (
	"fmt"
	"testing"
)

func TestCount(t *testing.T) {
	if Count() != 3 {
		t.Fatal("expected 3 orders")
	}
}

func ExampleCount() {
	fmt.Println(Count())
	// Output: 3
}

func ExampleInvoice() {
	fmt.Println(Invoice{Total: 42}.Total)
	// Output: 42
}
GO
say 'go vet ./orders && go test ./orders'
go vet ./orders 2>&1 && go test ./orders 2>&1 | sed -E 's/\t[0-9.]+s$//'
echo "exit status $?"
