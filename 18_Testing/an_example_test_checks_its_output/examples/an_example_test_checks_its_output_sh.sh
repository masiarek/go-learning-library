#!/usr/bin/env bash
# An Example function with an "// Output:" comment is compiled and run by go
# test, and its printed output is compared with the comment. A wrong comment
# fails with a got/want report. "// Unordered output:" compares the lines as
# a set, which is what a range over a map needs. An Example with no Output
# comment is compiled but never run, and -list does not name it.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >order.go <<'GO'
// Package order totals a customer's order.
package order

import "fmt"

// Line is one line of an order: an item, how many, and the unit price in cents.
type Line struct {
	Item  string
	Qty   int
	Cents int
}

// Order is what one customer asked for.
type Order struct{ Lines []Line }

// Total is the order's value in cents.
func (o Order) Total() int {
	sum := 0
	for _, l := range o.Lines {
		sum += l.Qty * l.Cents
	}
	return sum
}

// Units counts the units of each item over all of the order's lines.
func (o Order) Units() map[string]int {
	units := map[string]int{}
	for _, l := range o.Lines {
		units[l.Item] += l.Qty
	}
	return units
}

// PrintUnits prints one line per item, in map order -- which is no order.
func (o Order) PrintUnits() {
	for item, n := range o.Units() {
		fmt.Printf("%s x%d\n", item, n)
	}
}
GO

cat >example_test.go <<'GO'
package order_test

import (
	"fmt"

	"example"
)

func ExampleOrder_Total() {
	o := order.Order{Lines: []order.Line{{"crate", 2, 1250}, {"pallet", 1, 9900}}}
	fmt.Println(o.Total())
	// Output: 12400
}

// The comment is wrong: two crates at 1250 come to 2500.
func ExampleOrder_Total_wrongComment() {
	o := order.Order{Lines: []order.Line{{"crate", 2, 1250}}}
	fmt.Println(o.Total())
	// Output: 2400
}

func ExampleOrder_PrintUnits() {
	o := order.Order{Lines: []order.Line{{"crate", 2, 1250}, {"pallet", 1, 9900}, {"crate", 3, 1250}}}
	o.PrintUnits()
	// Unordered output:
	// pallet x1
	// crate x5
}

// No Output comment: compiled, shown in the documentation, never run.
func ExampleOrder_PrintUnits_notRun() {
	o := order.Order{Lines: []order.Line{{"crate", 2, 1250}}}
	o.PrintUnits()
}
GO

say() { printf '$ %s\n' "$*"; }

tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v'
go test -v >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test -list .'
go test -list . >test.txt 2>&1
status=$?
tidy
echo "exit status $status"
