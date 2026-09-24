// Kata: a Reading struct is written in the order the fields came to mind.
// Reorder its fields so that the struct is as small as it can be, and print
// how many bytes of padding each version carries and what an array of a
// thousand costs.
//
//	go build struct_layout_and_padding_kata_go.go && ./struct_layout_and_padding_kata_go
package main

import (
	"fmt"
	"unsafe"
)

// Reading, as first written: 1 + 8 + 4 + 1 + 8 = 22 bytes of data.
type Reading struct {
	Valid   bool
	Value   float64
	Sensor  int32
	Flagged bool
	At      int64
}

// Compact holds the same fields, sorted by alignment, largest first.
type Compact struct {
	Value   float64
	At      int64
	Sensor  int32
	Valid   bool
	Flagged bool
}

func main() {
	var r Reading
	var c Compact
	data := unsafe.Sizeof(r.Valid) + unsafe.Sizeof(r.Value) + unsafe.Sizeof(r.Sensor) + unsafe.Sizeof(r.Flagged) + unsafe.Sizeof(r.At)
	fmt.Println("bytes of field data in either struct:", data)
	fmt.Println("Reading: Sizeof", unsafe.Sizeof(r), " padding", unsafe.Sizeof(r)-data)
	fmt.Println("  Offsetof: Valid", unsafe.Offsetof(r.Valid), " Value", unsafe.Offsetof(r.Value), " Sensor", unsafe.Offsetof(r.Sensor), " Flagged", unsafe.Offsetof(r.Flagged), " At", unsafe.Offsetof(r.At))
	fmt.Println("Compact: Sizeof", unsafe.Sizeof(c), " padding", unsafe.Sizeof(c)-data)
	fmt.Println("  Offsetof: Value", unsafe.Offsetof(c.Value), " At", unsafe.Offsetof(c.At), " Sensor", unsafe.Offsetof(c.Sensor), " Valid", unsafe.Offsetof(c.Valid), " Flagged", unsafe.Offsetof(c.Flagged))
	fmt.Println("[1000]Reading:", unsafe.Sizeof([1000]Reading{}), "bytes   [1000]Compact:", unsafe.Sizeof([1000]Compact{}), "bytes")
}
