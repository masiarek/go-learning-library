// Kata: an iterator made by a constructor that captures its argument, and a
// Seq2 that pairs each element with its position -- ranged over, and then
// called by hand with the same function the loop body became.
//
//	go build range_over_a_function_kata_go.go && ./range_over_a_function_kata_go
package main

import (
	"fmt"
	"iter"
)

// Countdown returns an iterator over from, from-1, ..., 1. The returned
// function is the iterator; Countdown itself only captures from.
func Countdown(from int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for n := from; n >= 1; n-- {
			fmt.Println("countdown: yielding", n)
			if !yield(n) {
				return
			}
		}
		fmt.Println("countdown: done")
	}
}

// Indexed yields each sensor name with its position.
func Indexed(names []string) iter.Seq2[int, string] {
	return func(yield func(int, string) bool) {
		for i, name := range names {
			if !yield(i, name) {
				return
			}
		}
	}
}

func main() {
	for n := range Countdown(3) {
		fmt.Println("loop: got", n)
	}
	for i, name := range Indexed([]string{"hall", "garage", "attic"}) {
		fmt.Printf("loop: sensor %d is %s\n", i, name)
	}
	// The loop above and this call are the same thing.
	Indexed([]string{"hall", "garage"})(func(i int, name string) bool {
		fmt.Printf("by hand: sensor %d is %s\n", i, name)
		return true
	})
}
