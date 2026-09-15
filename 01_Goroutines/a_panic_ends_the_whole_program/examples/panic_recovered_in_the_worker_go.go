// The recover that works is the one in the goroutine that panicked. Deferred
// at the top of the worker, it turns the panic into an error, and the error
// travels back on the channel like any other result.
//
//	go run panic_recovered_in_the_worker_go.go
package main

import "fmt"

type total struct {
	cents int
	err   error
}

func sumPrices(prices []int) (cents int) {
	for i := 0; i <= len(prices); i++ { // one step too far
		cents += prices[i]
	}
	return cents
}

func main() {
	results := make(chan total)
	go func() {
		defer func() {
			if r := recover(); r != nil {
				results <- total{err: fmt.Errorf("worker panicked: %v", r)}
			}
		}()
		results <- total{cents: sumPrices([]int{1999, 450, 1200})}
	}()

	r := <-results
	fmt.Println("main: received err:", r.err)
	fmt.Println("main: still running; returning normally")
}
