// runtime.AddCleanup attaches a function that runs some time after the
// object becomes unreachable; weak.Make gives a pointer that does not keep
// it alive. Neither happens while the object is still in use, and "in use"
// means a later use in the code, not the end of a scope: runtime.KeepAlive
// is that later use. runtime.SetFinalizer is the older mechanism.
//
//	go build a_cleanup_runs_after_the_last_reference_go.go && ./a_cleanup_runs_after_the_last_reference_go
package main

import (
	"fmt"
	"runtime"
	"time"
	"weak"
)

type Session struct {
	id  int
	buf []byte
}

// collectUntil runs the collector until done receives, at most tries times.
// A cleanup runs in its own goroutine some time after the collection that
// found the object dead, so one runtime.GC() is not a guarantee.
func collectUntil(done <-chan int, tries int) (int, bool) {
	for range tries {
		runtime.GC()
		select {
		case id := <-done:
			return id, true
		case <-time.After(50 * time.Millisecond):
		}
	}
	return 0, false
}

func main() {
	closed := make(chan int, 1)
	s := &Session{id: 7, buf: make([]byte, 1024)}
	w := weak.Make(s)
	runtime.AddCleanup(s, func(id int) { closed <- id }, s.id)
	fmt.Println("weak.Value() while s is in use:", w.Value() == s)

	runtime.GC()
	time.Sleep(20 * time.Millisecond)
	fmt.Println("after a GC while s is still in use: cleanup ran:", len(closed) > 0, " weak is nil:", w.Value() == nil)
	runtime.KeepAlive(s) // the last use of s: it was reachable up to here

	id, ok := collectUntil(closed, 20)
	fmt.Println("after the last use of s: cleanup ran:", ok, " with id:", id)
	fmt.Println("weak pointer is nil:", w.Value() == nil)

	// The older mechanism hands the finalizer the object itself.
	finalized := make(chan int, 1)
	old := &Session{id: 8}
	runtime.SetFinalizer(old, func(o *Session) { finalized <- o.id })
	id, ok = collectUntil(finalized, 20)
	fmt.Println("finalizer ran:", ok, " with id:", id)
}
