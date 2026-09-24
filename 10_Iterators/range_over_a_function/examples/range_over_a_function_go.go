// A function of type func(yield func(int) bool) can be ranged over. The loop
// body becomes the yield argument, so the producer and the loop take turns on
// one goroutine, and the order in which the two sides print cannot vary.
//
//	go build range_over_a_function_go.go && ./range_over_a_function_go
package main

import (
	"fmt"
	"iter"
)

// Readings is an iterator: it calls yield once per reading, and stops as soon
// as yield returns false.
func Readings(yield func(int) bool) {
	for _, r := range []int{21, 19, 23} {
		fmt.Println("producer: yielding", r)
		if !yield(r) {
			fmt.Println("producer: the loop asked me to stop")
			return
		}
		fmt.Println("producer: yield returned true, continuing")
	}
	fmt.Println("producer: no more readings, returning")
}

// Labelled yields each reading with the name of its sensor: two values per
// element, which is what a two-variable range needs.
func Labelled(yield func(string, int) bool) {
	_ = yield("hall", 21) && yield("garage", 19) && yield("attic", 23)
}

func main() {
	fmt.Println("-- for r := range Readings")
	for r := range Readings {
		fmt.Println("loop: got", r)
	}
	fmt.Println("main: the loop ended")

	fmt.Println("-- the same thing, written as a call")
	Readings(func(r int) bool {
		fmt.Println("loop: got", r)
		return true
	})

	fmt.Println("-- iter.Seq and iter.Seq2 are names for these function types")
	var readings iter.Seq[int] = Readings
	var labelled iter.Seq2[string, int] = Labelled
	fmt.Printf("%T\n%T\n", readings, labelled)
	for name, r := range labelled {
		fmt.Printf("loop: %s = %d\n", name, r)
	}

	fmt.Println("-- func(func() bool) is the third shape: no values at all")
	ticks := func(yield func() bool) {
		for range 2 {
			if !yield() {
				return
			}
		}
	}
	for range ticks {
		fmt.Println("loop: tick")
	}
}
