// An iterator makes each element when the loop asks for it, so an infinite
// sequence is fine to range over, and Filter and Take compose without ever
// building a slice. A counter says how many elements the producer made.
//
//	go build an_iterator_is_lazy_go.go && ./an_iterator_is_lazy_go
package main

import (
	"fmt"
	"iter"
)

// produced counts every element Naturals handed to yield.
var produced int

// Naturals yields 1, 2, 3, ... for as long as the loop wants them.
func Naturals(yield func(int) bool) {
	for n := 1; ; n++ {
		produced++
		if !yield(n) {
			return
		}
	}
}

// Filter yields the elements of seq that keep accepts. Nothing runs until
// the returned iterator is ranged over.
func Filter[V any](seq iter.Seq[V], keep func(V) bool) iter.Seq[V] {
	return func(yield func(V) bool) {
		for v := range seq {
			if keep(v) && !yield(v) {
				return
			}
		}
	}
}

// Take yields at most n elements of seq, then stops asking seq for more.
func Take[V any](seq iter.Seq[V], n int) iter.Seq[V] {
	return func(yield func(V) bool) {
		if n <= 0 {
			return
		}
		taken := 0
		for v := range seq {
			if !yield(v) {
				return
			}
			taken++
			if taken == n {
				return
			}
		}
	}
}

// firstSquares is the slice version: it has to be told how many to make, and
// makes all of them before the caller sees the first.
func firstSquares(n int) []int {
	squares := make([]int, 0, n)
	for i := 1; i <= n; i++ {
		squares = append(squares, i*i)
	}
	return squares
}

func main() {
	fmt.Println("-- range over an infinite sequence, with a break")
	for n := range Naturals {
		if n > 3 {
			break
		}
		fmt.Println("loop: got", n)
	}
	fmt.Println("produced:", produced)

	fmt.Println("-- compose Filter and Take: nothing runs until the range")
	produced = 0
	multiplesOfSeven := Filter(Naturals, func(n int) bool { return n%7 == 0 })
	firstFour := Take(multiplesOfSeven, 4)
	fmt.Println("built the pipeline; produced:", produced)
	for n := range firstFour {
		fmt.Println("loop: got", n)
	}
	fmt.Println("produced:", produced)

	fmt.Println("-- a slice has to know its length up front")
	fmt.Println("firstSquares(4):", firstSquares(4))
}
