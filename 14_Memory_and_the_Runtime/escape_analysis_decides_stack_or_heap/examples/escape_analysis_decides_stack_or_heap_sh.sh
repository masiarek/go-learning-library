#!/usr/bin/env bash
# go build -gcflags=-m prints one line for each decision escape analysis made.
# This script builds a fixed file and keeps only the lines that say where a
# value went: "moved to heap", "escapes to heap" and "does not escape". Every
# function is marked //go:noinline, so that main's inlined copies do not add
# a second verdict for each of them; the positions are stable because the
# file is fixed.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/orders.go" <<'GO'
package main

import "fmt"

// Order is 24 bytes: small enough for any frame.
type Order struct {
	ID    int
	Qty   int
	Price int
}

// total builds an Order and lets it go: the Order stays in this frame.
//
//go:noinline
func total(qty, price int) int {
	o := Order{Qty: qty, Price: price}
	return o.Qty * o.Price
}

// newOrder returns the address of a local: the local is moved to the heap.
//
//go:noinline
func newOrder(id int) *Order {
	o := Order{ID: id}
	return &o
}

// show hands o to fmt.Println, which takes it as an interface value.
//
//go:noinline
func show(o Order) {
	fmt.Println(o)
}

// counter returns a closure that outlives this frame and still uses n.
//
//go:noinline
func counter() func() int {
	n := 0
	return func() int { n++; return n }
}

// sumSmall's slice has a constant size of 8,000 bytes: it fits in a frame.
//
//go:noinline
func sumSmall() int {
	s := make([]int, 1000)
	for i := range s {
		s[i] = i
	}
	return s[999]
}

// sumBig's slice has a constant size too, but 800,000 bytes is more than
// the compiler will put in a frame.
//
//go:noinline
func sumBig() int {
	s := make([]int, 100000)
	for i := range s {
		s[i] = i
	}
	return s[99999]
}

func main() {
	next := counter()
	show(Order{ID: total(3, 7) + newOrder(1).ID + next() + sumSmall() + sumBig()})
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build -gcflags=-m orders.go 2>&1 | grep -E "moved to heap|escapes to heap|does not escape"'
(cd "$dir" && go build -gcflags=-m orders.go 2>&1) | grep -E 'moved to heap|escapes to heap|does not escape'
echo "exit status ${PIPESTATUS[0]}"
