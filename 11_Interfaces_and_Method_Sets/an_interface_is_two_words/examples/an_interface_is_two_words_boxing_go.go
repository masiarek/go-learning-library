// Putting a value into an interface -- boxing -- copies it to the heap so the
// data word has something to point at, unless the runtime already has that
// value: integers 0 to 255 come from a static table, zero-size values and
// empty strings need no storage, and a pointer is stored in the data word
// itself. testing.AllocsPerRun counts the heap allocations per boxing. Each
// value comes through a //go:noinline function so that the compiler cannot
// fold it into a constant, which it turns into static data at compile time
// (the last row).
//
//	go build an_interface_is_two_words_boxing_go.go && ./an_interface_is_two_words_boxing_go
package main

import (
	"fmt"
	"testing"
)

type Order struct{ ID, Qty int }

var sink any

//go:noinline
func intValue(n int) int { return n }

//go:noinline
func byteValue(b byte) byte { return b }

//go:noinline
func floatValue(f float64) float64 { return f }

//go:noinline
func stringValue(s string) string { return s }

//go:noinline
func orderValue(o Order) Order { return o }

func row(what string, f func()) {
	fmt.Printf("%-24s %v\n", what, testing.AllocsPerRun(1000, f))
}

func main() {
	seven, v255, v256, v300, minusOne := intValue(7), intValue(255), intValue(256), intValue(300), intValue(-1)
	b255 := byteValue(255)
	zero, pi := floatValue(0), floatValue(3.14)
	empty, invoice := stringValue(""), stringValue("invoice")
	order := orderValue(Order{ID: 1, Qty: 2})
	pointer := &order
	var nothing struct{}

	fmt.Printf("%-24s %s\n", "value boxed into any", "allocations per boxing")
	row("int 7", func() { sink = seven })
	row("int 255", func() { sink = v255 })
	row("int 256", func() { sink = v256 })
	row("int 300", func() { sink = v300 })
	row("int -1", func() { sink = minusOne })
	row("byte 255", func() { sink = b255 })
	row("float64 0", func() { sink = zero })
	row("float64 3.14", func() { sink = pi })
	row("string \"\"", func() { sink = empty })
	row("string \"invoice\"", func() { sink = invoice })
	row("Order{1, 2}", func() { sink = order })
	row("struct{}{}", func() { sink = nothing })
	row("*Order", func() { sink = pointer })
	row("nil", func() { sink = nil })
	row("the constant 300", func() { sink = 300 })
}
