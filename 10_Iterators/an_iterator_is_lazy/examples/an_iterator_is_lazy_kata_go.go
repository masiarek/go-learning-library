// Kata: an infinite Fibonacci iterator, a TakeWhile adapter, and a counter
// that shows the producer made exactly one number more than was printed.
//
//	go build an_iterator_is_lazy_kata_go.go && ./an_iterator_is_lazy_kata_go
package main

import (
	"fmt"
	"iter"
)

// produced counts every number Fibonacci handed to yield.
var produced int

// Fibonacci yields 1, 1, 2, 3, 5, ... without end.
func Fibonacci(yield func(int) bool) {
	a, b := 1, 1
	for {
		produced++
		if !yield(a) {
			return
		}
		a, b = b, a+b
	}
}

// TakeWhile yields elements of seq until keep rejects one, then stops seq.
func TakeWhile[V any](seq iter.Seq[V], keep func(V) bool) iter.Seq[V] {
	return func(yield func(V) bool) {
		for v := range seq {
			if !keep(v) || !yield(v) {
				return
			}
		}
	}
}

func main() {
	var below100 []int
	for n := range TakeWhile(Fibonacci, func(n int) bool { return n < 100 }) {
		below100 = append(below100, n)
	}
	fmt.Println(below100)
	fmt.Printf("printed %d numbers; the producer made %d\n", len(below100), produced)
}
