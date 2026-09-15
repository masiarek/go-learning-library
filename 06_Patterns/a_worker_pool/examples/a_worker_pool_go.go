// A worker pool: three workers take jobs from one channel and send results on
// another. Each job carries its index, and main stores each result at that
// index, so the report comes out in input order however the jobs were
// scheduled. The pool shuts down in three steps: the feeder closes jobs, each
// worker's range loop ends and it returns, and once all three have returned a
// WaitGroup lets the closer close results, which ends main's range loop.
//
//	go build a_worker_pool_go.go && ./a_worker_pool_go
package main

import (
	"fmt"
	"strings"
	"sync"
	"sync/atomic"
)

const workers = 3

type job struct {
	index int
	line  string
}

type result struct {
	index int
	words int
}

func main() {
	lines := []string{
		"a goroutine is a function running concurrently",
		"a channel carries values between goroutines",
		"close the jobs channel once every job is sent",
		"each worker returns when its range loop ends",
		"results are stored by job index",
		"so the report keeps the order of the input",
	}

	jobs := make(chan job)
	results := make(chan result)

	// The feeder sends from its own goroutine, so that main is free to receive
	// results while jobs are still going out.
	go func() {
		defer close(jobs) // step 1: no more jobs
		for i, line := range lines {
			jobs <- job{index: i, line: line}
		}
	}()

	var pool sync.WaitGroup
	var busy, mostBusy atomic.Int32
	for range workers {
		pool.Go(func() {
			for j := range jobs { // step 2: ends when jobs is closed and drained
				n := busy.Add(1)
				for m := mostBusy.Load(); n > m && !mostBusy.CompareAndSwap(m, n); m = mostBusy.Load() {
				}
				words := len(strings.Fields(j.line))
				busy.Add(-1)
				results <- result{index: j.index, words: words}
			}
		})
	}

	go func() {
		pool.Wait()    // every worker has returned, so none will send again
		close(results) // step 3
	}()

	report := make([]int, len(lines))
	received := 0
	for r := range results { // arrival order is the scheduler's
		report[r.index] = r.words
		received++
	}

	fmt.Printf("workers:                    %d\n", workers)
	fmt.Printf("jobs sent:                  %d\n", len(lines))
	fmt.Printf("results received:           %d\n", received)
	fmt.Printf("results closed:             after all %d workers returned\n", workers)
	fmt.Printf("most jobs in progress <= %d: %t\n", workers, mostBusy.Load() <= workers)
	fmt.Println("report, in input order:")
	for i, line := range lines {
		fmt.Printf("  %d. %d words  %s\n", i+1, report[i], line)
	}
}
