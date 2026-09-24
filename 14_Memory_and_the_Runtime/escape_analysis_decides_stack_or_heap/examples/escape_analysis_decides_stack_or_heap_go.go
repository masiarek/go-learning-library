// testing.AllocsPerRun counts heap allocations per call of a function, so a
// program can check what -gcflags=-m claimed: 0 for a value that stays in
// its frame, 1 for each value the compiler moved to the heap, and the cases
// -m cannot see because they are decided at run time.
//
//	go build escape_analysis_decides_stack_or_heap_go.go && ./escape_analysis_decides_stack_or_heap_go
package main

import (
	"fmt"
	"os"
	"testing"
)

// Order is 24 bytes: small enough for any frame.
type Order struct {
	ID    int
	Qty   int
	Price int
}

// Package-level sinks: a store into one is a use the compiler cannot see past.
var (
	lastOrder *Order
	lastValue any
	total     int
)

// newOrder returns the address of a local: the local is moved to the heap.
//
//go:noinline
func newOrder(id int) *Order {
	o := Order{ID: id}
	return &o
}

// counter returns a closure that outlives this frame and still uses n.
//
//go:noinline
func counter() func() int {
	n := 0
	return func() int { n++; return n }
}

func main() {
	report := func(what string, f func()) {
		fmt.Printf("%-50s %v\n", what, testing.AllocsPerRun(100, f))
	}

	report("an Order built, used and dropped in one frame:", func() {
		o := Order{Qty: 3, Price: 7}
		total += o.Qty * o.Price
	})
	report("a pointer to a local, returned and stored:", func() {
		lastOrder = newOrder(1)
	})
	report("a closure that captures its counter:", func() {
		next := counter()
		total += next()
	})

	// Values computed at run time, so the compiler cannot pre-build the
	// interface value for them the way it does for a constant.
	big := int64(len(os.Args)) + 999
	small := int64(len(os.Args)) + 6
	report("an int64 of 1000 stored in an interface:", func() { lastValue = big })
	report("an int64 of 7 stored in an interface:", func() { lastValue = small })

	report("make([]int, 1000), constant size, used here:", func() {
		s := make([]int, 1000)
		total += s[999]
	})
	report("make([]int, 100000), constant size, used here:", func() {
		s := make([]int, 100000)
		total += s[99999]
	})
	n := 4
	report("make([]int, n) with n = 4 at run time:", func() {
		s := make([]int, n)
		total += s[n-1]
	})
	n = 1000
	report("make([]int, n) with n = 1000 at run time:", func() {
		s := make([]int, n)
		total += s[n-1]
	})

	report("append 4 orders to a slice with room for 4:", func() {
		s := make([]int, 0, 4)
		for i := range 4 {
			s = append(s, i)
		}
		total += s[3]
	})
	report("append 5 orders to a slice with room for 4:", func() {
		s := make([]int, 0, 4)
		for i := range 5 {
			s = append(s, i)
		}
		total += s[4]
	})
}
