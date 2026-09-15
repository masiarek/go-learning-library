// A sync.WaitGroup is a counter, and Wait returns as soon as it reads zero. So
// Add has to run before the goroutine starts: an Add inside the goroutine can
// come after Wait has already looked.
//
// Each task waits at a gate before doing anything. The gate stands in for the
// scheduler, which may leave a new goroutine unstarted for as long as it likes;
// here it is simply told to.
//
//	go build a_waitgroup_counts_goroutines_go.go && ./a_waitgroup_counts_goroutines_go
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
)

const tasks = 3

func main() {
	// Wrong: Add inside the goroutine.
	{
		var wg sync.WaitGroup
		var finished atomic.Int64
		gate := make(chan struct{})
		exited := make(chan struct{})
		for range tasks {
			go func() {
				defer func() { exited <- struct{}{} }()
				<-gate
				wg.Add(1) // too late: main may already be past Wait
				defer wg.Done()
				finished.Add(1)
			}()
		}
		wg.Wait()
		fmt.Printf("Add inside the goroutine:   Wait returned, %d of %d tasks finished\n", finished.Load(), tasks)

		close(gate)
		for range tasks {
			<-exited
		}
		fmt.Printf("                            (%d finished after that, with nobody waiting)\n", finished.Load())
	}

	// Right: Add before the go statement. Same gate, opened from elsewhere.
	{
		var wg sync.WaitGroup
		var finished atomic.Int64
		gate := make(chan struct{})
		for range tasks {
			wg.Add(1)
			go func() {
				defer wg.Done()
				<-gate
				finished.Add(1)
			}()
		}
		go close(gate)
		wg.Wait()
		fmt.Printf("Add before the go statement: Wait returned, %d of %d tasks finished\n", finished.Load(), tasks)
	}

	// Go 1.25: wg.Go does the Add itself, before it starts the goroutine.
	{
		var wg sync.WaitGroup
		var finished atomic.Int64
		gate := make(chan struct{})
		for range tasks {
			wg.Go(func() {
				<-gate
				finished.Add(1)
			})
		}
		go close(gate)
		wg.Wait()
		fmt.Printf("wg.Go:                       Wait returned, %d of %d tasks finished\n", finished.Load(), tasks)
	}
}
