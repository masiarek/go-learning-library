#!/usr/bin/env bash
# The name of an Example function says what it documents: ExampleT_M for a
# method, ExampleT_M_suffix for a second example, and the suffix starts with a
# lowercase letter. go vet's "tests" analyzer checks the names against the
# package, and go test runs that analyzer before it builds the test binary.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >order.go <<'GO'
package order

// Order is what one customer asked for.
type Order struct{ Cents int }

// Total is the order's value in cents.
func (o Order) Total() int { return o.Cents }
GO

cat >example_test.go <<'GO'
package order_test

import (
	"fmt"

	"example"
)

// A lowercase suffix is fine: this is a second example of Order.Total.
func ExampleOrder_Total_discounted() {
	fmt.Println(order.Order{Cents: 1000}.Total() * 9 / 10)
	// Output: 900
}

// An uppercase suffix is read as a method name -- and Order has no Discounted.
func ExampleOrder_Total_Discounted() {
	fmt.Println(order.Order{Cents: 1000}.Total())
	// Output: 1000
}

// Nothing in the package is called Invoice.
func ExampleInvoice() {
	fmt.Println("invoice")
	// Output: invoice
}

// Order has no method Ship.
func ExampleOrder_Ship() {
	fmt.Println("shipped")
	// Output: shipped
}

// An example takes no parameters.
func ExampleOrder(o order.Order) {
	fmt.Println(o.Total())
	// Output: 0
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
