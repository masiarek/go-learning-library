// Goroutines are cheap: start 100,000 that block on a channel, count them,
// release them, and count again. runtime.NumGoroutine is read only when what
// it counts has settled, so the three numbers are the same on every run.
//
//	go run goroutines_are_cheap_go.go
package main

import (
	"fmt"
	"runtime"
	"sync"
)

const workers = 100_000

func main() {
	fmt.Printf("goroutines when main starts:    %6d\n", runtime.NumGoroutine())

	release := make(chan struct{})
	var started, finished sync.WaitGroup
	started.Add(workers)
	for range workers {
		finished.Go(func() {
			started.Done() // this goroutine exists and is about to block
			<-release
		})
	}
	started.Wait() // every worker has got as far as Done
	fmt.Printf("goroutines while workers block: %6d\n", runtime.NumGoroutine())

	close(release) // one close wakes every receiver
	finished.Wait()

	// Wait returns once every function has returned, not once every goroutine
	// has gone, so wait for the count itself.
	for runtime.NumGoroutine() > 1 {
		runtime.Gosched()
	}
	fmt.Printf("goroutines after release:       %6d\n", runtime.NumGoroutine())
}
