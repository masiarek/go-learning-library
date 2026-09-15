// A buffered channel with room for 3 is a semaphore with 3 slots: a send takes
// a slot, and blocks while all 3 are taken; a receive gives one back. Five
// resize tasks share it. The tasks that get in wait at a barrier, which main
// opens only after it has seen 3 inside and shown that a 4th acquire would
// block, so the most tasks inside at once is exactly 3, on every run.
//
//	go build a_buffered_channel_as_a_semaphore_go.go && ./a_buffered_channel_as_a_semaphore_go
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
)

const (
	tasks = 5
	slots = 3
)

func main() {
	sem := make(chan struct{}, slots) // the semaphore: its buffer holds the taken slots

	barrier := make(chan struct{}) // closed by main: until then, no task inside may leave
	entered := make(chan struct{}) // a task reports here once it holds a slot

	var started, all sync.WaitGroup
	var inside, mostInside atomic.Int32

	started.Add(tasks)
	for range tasks {
		all.Go(func() {
			started.Done()

			sem <- struct{}{} // acquire: blocks while every slot is taken
			n := inside.Add(1)
			for m := mostInside.Load(); n > m && !mostInside.CompareAndSwap(m, n); m = mostInside.Load() {
			}
			entered <- struct{}{}

			<-barrier // the resize would happen here

			inside.Add(-1)
			<-sem // release: gives the slot back
		})
	}

	started.Wait()
	for range slots {
		<-entered
	}
	fmt.Printf("slots:                   %d\n", cap(sem))
	fmt.Printf("tasks started:           %d\n", tasks)
	fmt.Printf("tasks inside:            %d\n", inside.Load())
	fmt.Printf("slots taken:             %d of %d\n", len(sem), cap(sem))
	fmt.Printf("started, not let in:     %d\n", tasks-int(inside.Load()))

	select {
	case sem <- struct{}{}:
		fmt.Println("a 4th acquire:           succeeded") // cannot happen: the buffer is full
		<-sem
	default:
		fmt.Println("a 4th acquire:           would block")
	}

	fmt.Println("main opens the barrier")
	close(barrier)
	for range tasks - slots {
		<-entered
	}
	all.Wait()

	fmt.Printf("tasks finished:          %d\n", tasks)
	fmt.Printf("slots taken:             %d of %d\n", len(sem), cap(sem))
	fmt.Printf("most inside at once:     %d\n", mostInside.Load())
}
