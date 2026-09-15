// If you want a handle, build one: a function that starts the goroutine and
// returns a channel with room for exactly one result. The room matters -- it
// lets the goroutine send and end even if nobody ever receives.
//
//	go run no_handle_future_go.go
package main

import (
	"fmt"
	"runtime"
	"strconv"
	"time"
)

// result is a value and the error that came with it.
type result[T any] struct {
	value T
	err   error
}

// start runs f in a new goroutine and returns the channel its result will arrive on.
func start[T any](f func() (T, error)) <-chan result[T] {
	ch := make(chan result[T], 1)
	go func() {
		value, err := f()
		ch <- result[T]{value, err}
	}()
	return ch
}

// settle waits until main is the only goroutine left, or two seconds have
// passed, and returns how many goroutines there are.
func settle() int {
	deadline := time.Now().Add(2 * time.Second)
	for runtime.NumGoroutine() > 1 && time.Now().Before(deadline) {
		runtime.Gosched()
	}
	return runtime.NumGoroutine()
}

func main() {
	price := start(func() (float64, error) { return strconv.ParseFloat("19.99", 64) })
	quantity := start(func() (int, error) { return strconv.Atoi("three") })

	// Each result has its own channel, so main takes them in the order it likes.
	q := <-quantity
	p := <-price
	fmt.Printf("quantity: %d, err: %v\n", q.value, q.err)
	fmt.Printf("price: %.2f, err: %v\n", p.value, p.err)

	// A result nobody receives: the buffer holds it, and the goroutine ends.
	start(func() (int, error) { return strconv.Atoi("42") })
	fmt.Println("goroutines after a buffered send nobody receives:  ", settle())

	// The same send on an unbuffered channel waits for a receiver forever.
	unbuffered := make(chan int)
	go func() { unbuffered <- 42 }()
	fmt.Println("goroutines after an unbuffered send nobody receives:", settle())
}
