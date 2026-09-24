// iter.Pull turns a push iterator into next and stop. The iterator starts on
// the first next, runs one step per call, and finishes -- its deferred
// cleanup included -- either when it runs out on its own or when stop is
// called. After stop, next returns the zero value and false.
//
//	go build iter_pull_needs_its_stop_go.go && ./iter_pull_needs_its_stop_go
package main

import (
	"fmt"
	"iter"
)

// Orders yields three orders and says what it is doing at each step.
func Orders(yield func(string) bool) {
	defer fmt.Println("producer: deferred cleanup ran")
	for _, o := range []string{"order-1", "order-2", "order-3"} {
		fmt.Println("producer: yielding", o)
		if !yield(o) {
			fmt.Println("producer: yield returned false")
			return
		}
	}
	fmt.Println("producer: finished on its own")
}

func main() {
	fmt.Println("-- pull two, then stop")
	next, stop := iter.Pull(iter.Seq[string](Orders))
	fmt.Println("main: iter.Pull returned; nothing has run yet")
	order, ok := next()
	fmt.Printf("main: next -> %q, %t\n", order, ok)
	order, ok = next()
	fmt.Printf("main: next -> %q, %t\n", order, ok)
	fmt.Println("main: calling stop")
	stop()
	fmt.Println("main: stop returned")
	order, ok = next()
	fmt.Printf("main: next after stop -> %q, %t\n", order, ok)
	stop()
	fmt.Println("main: a second stop is allowed and does nothing")

	fmt.Println("-- pull to the end")
	next, stop = iter.Pull(iter.Seq[string](Orders))
	for {
		order, ok := next()
		fmt.Printf("main: next -> %q, %t\n", order, ok)
		if !ok {
			break
		}
	}
	stop()
	fmt.Println("main: stop after the end is allowed and does nothing")

	fmt.Println("-- stop before any next")
	next, stop = iter.Pull(iter.Seq[string](Orders))
	stop()
	fmt.Println("main: stop returned; the producer never started")
	order, ok = next()
	fmt.Printf("main: next -> %q, %t\n", order, ok)

	fmt.Println("-- a panic in the producer comes out of next")
	func() {
		defer func() { fmt.Println("main: recovered:", recover()) }()
		next, stop := iter.Pull(iter.Seq[int](func(yield func(int) bool) {
			yield(1)
			panic("sensor unplugged")
		}))
		defer stop()
		n, ok := next()
		fmt.Printf("main: next -> %d, %t\n", n, ok)
		n, ok = next()
		fmt.Printf("main: next -> %d, %t\n", n, ok)
	}()
}
