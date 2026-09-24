// Kata: Zip two sequences, which a push iterator cannot do on its own. One
// side is ranged over; the other is pulled in step with it, and the deferred
// stop is what lets the pulled side finish when it is the longer one.
//
//	go build iter_pull_needs_its_stop_kata_go.go && ./iter_pull_needs_its_stop_kata_go
package main

import (
	"fmt"
	"iter"
)

// Named returns an iterator over values that reports when it finishes.
func Named[V any](name string, values ...V) iter.Seq[V] {
	return func(yield func(V) bool) {
		defer fmt.Printf("%s: cleanup ran\n", name)
		for _, v := range values {
			if !yield(v) {
				return
			}
		}
	}
}

// Zip pairs the elements of a and b and ends with the shorter of the two.
func Zip[A, B any](a iter.Seq[A], b iter.Seq[B]) iter.Seq2[A, B] {
	return func(yield func(A, B) bool) {
		next, stop := iter.Pull(b)
		defer func() {
			fmt.Println("zip: calling stop")
			stop()
		}()
		for va := range a {
			vb, ok := next()
			if !ok || !yield(va, vb) {
				return
			}
		}
	}
}

func main() {
	sensors := Named("sensors", "hall", "garage")
	readings := Named("readings", 21, 19, 23)
	for name, r := range Zip(sensors, readings) {
		fmt.Printf("%s = %d\n", name, r)
	}
	fmt.Println("main: the loop ended")
}
