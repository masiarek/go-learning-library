// unsafe.Pointer converts between pointer types without converting the bytes
// they point at: *(*uint64)(unsafe.Pointer(&f)) is the bit pattern of the
// float64 f, which is exactly how math.Float64bits is written. unsafe.String
// and unsafe.Slice reinterpret a []byte as a string and back without a copy.
//
//	go build unsafe_pointer_reinterprets_memory_go.go && ./unsafe_pointer_reinterprets_memory_go
package main

import (
	"fmt"
	"math"
	"testing"
	"unsafe"
)

type Reading struct {
	Station uint16
	Value   float64
}

var (
	sinkString string
	sinkBytes  []byte
)

func main() {
	// Pattern 1: *T1 -> Pointer -> *T2, the bytes untouched.
	f := 1.5
	bits := *(*uint64)(unsafe.Pointer(&f))
	fmt.Printf("1.5 reinterpreted as uint64: %#016x\n", bits)
	fmt.Printf("math.Float64bits(1.5):      %#016x, equal %t\n", math.Float64bits(f), bits == math.Float64bits(f))
	quiet := uint64(0x7ff8000000000001)
	asFloat := *(*float64)(unsafe.Pointer(&quiet))
	fmt.Printf("%#016x reinterpreted as float64: %v, IsNaN %t\n", quiet, asFloat, math.IsNaN(asFloat))
	fmt.Printf("float64(%#x) converted instead: %v\n", uint64(0x40), float64(uint64(0x40)))

	// Pattern 3: through uintptr with arithmetic, in one expression -- or unsafe.Add.
	readings := [3]Reading{{1, 20.5}, {2, 21}, {3, 19.75}}
	second := (*Reading)(unsafe.Add(unsafe.Pointer(&readings[0]), unsafe.Sizeof(readings[0])))
	fmt.Println("unsafe.Add one Sizeof on from &readings[0]:", *second)
	third := *(*float64)(unsafe.Pointer(uintptr(unsafe.Pointer(&readings[2])) + unsafe.Offsetof(readings[2].Value)))
	fmt.Println("uintptr + Offsetof(Value) into readings[2]:", third)

	// Zero-copy []byte <-> string (Go 1.20).
	data := make([]byte, 64)
	for i := range data {
		data[i] = 'a' + byte(i%26)
	}
	text := unsafe.String(unsafe.SliceData(data), len(data))
	fmt.Printf("unsafe.String over 64 bytes: %q... len %d\n", text[:8], len(text))
	view := unsafe.Slice(unsafe.StringData(text), len(text))
	fmt.Println("unsafe.Slice of that string: same first byte as data:", &view[0] == &data[0])
	fmt.Println("string(data) copies:         same first byte as data:", unsafe.StringData(string(data)) == &data[0])

	// What the copy costs, and what the reinterpretation saves.
	fmt.Println("allocations per call, string(data):                     ", testing.AllocsPerRun(100, func() { sinkString = string(data) }))
	fmt.Println("allocations per call, unsafe.String(SliceData, len):    ", testing.AllocsPerRun(100, func() { sinkString = unsafe.String(unsafe.SliceData(data), len(data)) }))
	fmt.Println("allocations per call, []byte(text):                     ", testing.AllocsPerRun(100, func() { sinkBytes = []byte(text) }))
	fmt.Println("allocations per call, unsafe.Slice(StringData, len):    ", testing.AllocsPerRun(100, func() { sinkBytes = unsafe.Slice(unsafe.StringData(text), len(text)) }))
}
