// The two knobs of the collector, read and set from inside the program.
// debug.SetGCPercent and debug.SetMemoryLimit each return the previous
// setting; runtime.GC forces a cycle; with the collector off, garbage is
// never collected until a memory limit says it must be.
//
//	go build gogc_and_gomemlimit_tune_the_collector_go.go && ./gogc_and_gomemlimit_tune_the_collector_go
package main

import (
	"fmt"
	"math"
	"runtime"
	"runtime/debug"
)

// numGC is the number of completed collections since the program started.
func numGC() uint32 {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return m.NumGC
}

var slab []byte

// churn allocates total bytes in 1 MiB slabs and drops each one.
func churn(total int) {
	for range total >> 20 {
		slab = make([]byte, 1<<20)
	}
	slab = nil
}

func main() {
	fmt.Println("SetGCPercent(50) returned the default:", debug.SetGCPercent(50))
	fmt.Println("SetGCPercent(100) returned what was just set:", debug.SetGCPercent(100))
	fmt.Println("SetMemoryLimit(-1) leaves the limit alone and returns math.MaxInt64:", debug.SetMemoryLimit(-1) == math.MaxInt64)

	before := numGC()
	runtime.GC()
	fmt.Println("runtime.GC() increased NumGC:", numGC() > before)

	fmt.Println("SetGCPercent(-1) turns the collector off; it returned:", debug.SetGCPercent(-1))
	before = numGC()
	churn(256 << 20)
	fmt.Println("collector off, no limit: 256 MiB of garbage ran a collection:", numGC() > before)

	fmt.Println("SetMemoryLimit(64<<20) returned math.MaxInt64:", debug.SetMemoryLimit(64<<20) == math.MaxInt64)
	before = numGC()
	churn(256 << 20)
	fmt.Println("collector off, 64 MiB limit: 256 MiB of garbage ran a collection:", numGC() > before)

	fmt.Println("SetMemoryLimit(-1) now returns:", debug.SetMemoryLimit(-1))
	fmt.Println("SetGCPercent(100) returned the -1 that was in force:", debug.SetGCPercent(100))
}
