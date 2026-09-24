// Kata: a Connection wraps a file descriptor. Give every Connection a
// cleanup that records the descriptor it closed. Open three, cancel the
// cleanup of the second with Cleanup.Stop, drop all three, collect, and
// print the descriptors that were closed, sorted, and that the stopped
// one was not.
//
//	go build a_cleanup_runs_after_the_last_reference_kata_go.go && ./a_cleanup_runs_after_the_last_reference_kata_go
package main

import (
	"fmt"
	"runtime"
	"slices"
	"time"
)

// Connection holds a string as well as the descriptor. A struct of one int
// would be a "tiny", pointer-free object, which the runtime packs into a
// shared 16-byte block whose cleanups wait for every object in the block.
type Connection struct {
	fd   int
	addr string
}

var closed = make(chan int, 8)

func open(fd int, addr string) (*Connection, runtime.Cleanup) {
	c := &Connection{fd: fd, addr: addr}
	return c, runtime.AddCleanup(c, func(fd int) { closed <- fd }, fd)
}

// collect runs the collector until want descriptors have been reported, or
// gives up after tries rounds.
func collect(want, tries int) []int {
	var fds []int
	for range tries {
		runtime.GC()
		for len(fds) < want {
			select {
			case fd := <-closed:
				fds = append(fds, fd)
				continue
			case <-time.After(50 * time.Millisecond):
			}
			break
		}
		if len(fds) == want {
			break
		}
	}
	slices.Sort(fds)
	return fds
}

func main() {
	first, _ := open(3, "db-1:5432")
	second, stop := open(4, "cache-1:6379")
	third, _ := open(5, "db-2:5432")
	stop.Stop()
	fmt.Println("open:", first.fd, second.fd, third.fd, " cleanup of 4 stopped")
	// No use of first, second or third after this line: all three are dead.

	fmt.Println("closed after collection:", collect(2, 20))
	runtime.GC()
	time.Sleep(50 * time.Millisecond)
	fmt.Println("the stopped cleanup reported anything:", len(closed) > 0)
}
