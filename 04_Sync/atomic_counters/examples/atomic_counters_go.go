// sync/atomic: an exact count with no lock, and a flag that exactly one of many
// goroutines can flip.
//
//	go build atomic_counters_go.go && ./atomic_counters_go
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
)

const workers = 8

// server can be closed by any number of goroutines at once; it shuts down once.
type server struct {
	closed    atomic.Bool
	shutdowns atomic.Int64
}

// Close reports whether this call is the one that shut the server down.
func (s *server) Close() bool {
	if !s.closed.CompareAndSwap(false, true) {
		return false // somebody else got there first
	}
	s.shutdowns.Add(1)
	return true
}

func main() {
	// 1. A counter: Add is a read, an add and a write that nothing can split.
	const perWorker = 100_000
	var views atomic.Int64 // the zero value is 0, ready to use
	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for range perWorker {
				views.Add(1)
			}
		})
	}
	wg.Wait()
	fmt.Printf("expected total:           %d\n", workers*perWorker)
	fmt.Printf("atomic.Int64 total:       %d\n", views.Load())

	// 2. First writer wins: every worker calls Close at the same moment.
	var srv server
	won := make([]bool, workers) // each goroutine writes only its own slot
	start := make(chan struct{})
	for i := range workers {
		wg.Go(func() {
			<-start
			won[i] = srv.Close()
		})
	}
	close(start) // release all of them together
	wg.Wait()

	winners := 0
	for _, w := range won {
		if w {
			winners++
		}
	}
	fmt.Printf("goroutines calling Close: %d\n", workers)
	fmt.Printf("calls that shut it down:  %d\n", winners)
	fmt.Printf("calls told it was closed: %d\n", workers-winners)
	fmt.Printf("shutdowns performed:      %d\n", srv.shutdowns.Load())
}
