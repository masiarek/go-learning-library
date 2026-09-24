// Kata: float32 bits through unsafe.Pointer, checked against math.Float32bits
// and back through math.Float32frombits, and a zero-copy view of a []byte as
// a string whose allocation count is measured against the copying conversion.
//
//	go build unsafe_pointer_reinterprets_memory_kata_go.go && ./unsafe_pointer_reinterprets_memory_kata_go
package main

import (
	"fmt"
	"math"
	"testing"
	"unsafe"
)

var sink string

func bitsOf(f float32) uint32   { return *(*uint32)(unsafe.Pointer(&f)) }
func fromBits(b uint32) float32 { return *(*float32)(unsafe.Pointer(&b)) }
func view(b []byte) string      { return unsafe.String(unsafe.SliceData(b), len(b)) }
func copyOf(b []byte) string    { return string(b) }
func allocs(f func()) float64   { return testing.AllocsPerRun(200, f) }
func check(f float32, b uint32) bool {
	return b == math.Float32bits(f) && fromBits(b) == math.Float32frombits(b)
}

func main() {
	for _, f := range []float32{1, -2.5, 0, 3e38} {
		b := bitsOf(f)
		fmt.Printf("%-8v bits %#08x  agrees with math: %t\n", f, b, check(f, b))
	}
	line := make([]byte, 48)
	for i := range line {
		line[i] = "0123456789"[i%10]
	}
	fmt.Println("view(line) == copyOf(line):", view(line) == copyOf(line))
	fmt.Println("allocations per call, copyOf:", allocs(func() { sink = copyOf(line) }))
	fmt.Println("allocations per call, view:  ", allocs(func() { sink = view(line) }))
	fmt.Println("rule: a view is valid only while the bytes are neither modified nor reused")
}
