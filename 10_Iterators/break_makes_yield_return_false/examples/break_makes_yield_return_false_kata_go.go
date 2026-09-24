// Kata: an iterator with a deferred cleanup, a search that returns from inside
// the loop, and a careless iterator caught by the runtime.
//
//	go build break_makes_yield_return_false_kata_go.go && ./break_makes_yield_return_false_kata_go
package main

import (
	"fmt"
	"iter"
	"slices"
)

// Batches yields orders in groups of size, and reports when it is done.
func Batches(orders []string, size int) iter.Seq[[]string] {
	return func(yield func([]string) bool) {
		defer fmt.Println("batches: cleanup ran")
		for start := 0; start < len(orders); start += size {
			end := min(start+size, len(orders))
			if !yield(orders[start:end]) {
				return
			}
		}
	}
}

// FirstBatchWith returns the first batch holding target. The return inside
// the loop makes yield return false inside Batches.
func FirstBatchWith(batches iter.Seq[[]string], target string) []string {
	for batch := range batches {
		if slices.Contains(batch, target) {
			return batch
		}
	}
	return nil
}

// Careless never looks at what yield returns.
func Careless(yield func(int) bool) {
	yield(1)
	yield(2)
}

func main() {
	orders := []string{"order-1", "order-2", "order-3", "order-4", "order-5"}
	fmt.Println("found:", FirstBatchWith(Batches(orders, 2), "order-3"))
	fmt.Println("found:", FirstBatchWith(Batches(orders, 2), "order-9"))

	defer func() { fmt.Println("recovered:", recover()) }()
	for n := range Careless {
		fmt.Println("got", n)
		break
	}
	fmt.Println("never printed")
}
