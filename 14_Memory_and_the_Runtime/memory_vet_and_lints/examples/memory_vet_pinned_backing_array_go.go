// A two-byte slice of a 64 MiB read keeps the whole 64 MiB alive: the slice
// header points into the big backing array, and the collector keeps what
// is pointed at. No tool flags this; a copy the size of what is needed is
// the fix. Measured with HeapAlloc after a forced collection.
//
//	go build memory_vet_pinned_backing_array_go.go && ./memory_vet_pinned_backing_array_go
package main

import (
	"fmt"
	"runtime"
)

func heapAllocMiB() uint64 {
	runtime.GC()
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return m.HeapAlloc >> 20
}

var magic []byte

func main() {
	fmt.Println("heap before the read is under 8 MiB:", heapAllocMiB() < 8)

	whole := make([]byte, 64<<20) // the whole file, read in one go
	whole[0], whole[1] = 'P', 'K'
	magic = whole[:2] // the two bytes the program actually keeps
	whole = nil
	fmt.Println("kept whole[:2]: len", len(magic), " cap", cap(magic))
	fmt.Println("  heap after collection is over 32 MiB:", heapAllocMiB() > 32)

	copied := make([]byte, len(magic))
	copy(copied, magic)
	magic = copied
	fmt.Println("kept a copy:    len", len(magic), " cap", cap(magic))
	fmt.Println("  heap after collection is under 8 MiB:", heapAllocMiB() < 8)
}
