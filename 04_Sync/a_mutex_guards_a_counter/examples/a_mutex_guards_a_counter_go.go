// Eight goroutines each count 100,000 page views into one shared counter. With
// a sync.Mutex around the increment, not one view is lost. The same program
// without the lock is demo/lost_updates.go, and its total changes on every run.
//
//	go build a_mutex_guards_a_counter_go.go && ./a_mutex_guards_a_counter_go
package main

import (
	"fmt"
	"sync"
)

const (
	workers   = 8
	perWorker = 100_000
)

// pageViews keeps the mutex next to the value it guards.
type pageViews struct {
	mu    sync.Mutex
	count int
}

func (p *pageViews) record() {
	p.mu.Lock()
	defer p.mu.Unlock() // runs on every way out of record, a panic included
	p.count++
}

func main() {
	var views pageViews // the zero value is an unlocked mutex and a count of 0
	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for range perWorker {
				views.record()
			}
		})
	}
	wg.Wait()

	fmt.Printf("workers:              %d\n", workers)
	fmt.Printf("views each:           %d\n", perWorker)
	fmt.Printf("expected total:       %d\n", workers*perWorker)
	fmt.Printf("total with a Mutex:   %d\n", views.count)
}
