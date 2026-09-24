// Kata: write withCollectorOff(f), which turns the collector off while f
// runs and restores the previous setting afterwards, even if f panics.
// Inside f, allocate 128 MiB of garbage and show that no collection ran;
// afterwards, show that the percentage is back to what it was.
//
//	go build gogc_and_gomemlimit_tune_the_collector_kata_go.go && ./gogc_and_gomemlimit_tune_the_collector_kata_go
package main

import (
	"fmt"
	"runtime"
	"runtime/debug"
)

func numGC() uint32 {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return m.NumGC
}

// withCollectorOff runs f with GC percent -1 and restores the previous
// setting on every way out, including a panic in f.
func withCollectorOff(f func()) {
	previous := debug.SetGCPercent(-1)
	defer debug.SetGCPercent(previous)
	f()
}

var slab []byte

func main() {
	fmt.Println("percent before:", debug.SetGCPercent(100))

	withCollectorOff(func() {
		fmt.Println("inside: SetGCPercent(-1) reads back", debug.SetGCPercent(-1))
		before := numGC()
		for range 128 {
			slab = make([]byte, 1<<20)
		}
		slab = nil
		fmt.Println("inside: 128 MiB of garbage ran a collection:", numGC() > before)
	})
	fmt.Println("after: percent restored to 100:", debug.SetGCPercent(100) == 100)

	func() {
		defer func() { recover() }()
		withCollectorOff(func() { panic("the work failed") })
	}()
	fmt.Println("after a panic inside: percent restored to 100:", debug.SetGCPercent(100) == 100)
}
