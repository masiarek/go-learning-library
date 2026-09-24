// Kata: an invoice lookup returns *Invoice for a value it builds on the spot,
// and its callers only read two fields. Return the Invoice by value instead,
// and prove with testing.AllocsPerRun that the pointer version allocates once
// per call and the value version not at all.
//
//	go build escape_analysis_decides_stack_or_heap_kata_go.go && ./escape_analysis_decides_stack_or_heap_kata_go
package main

import (
	"fmt"
	"testing"
)

type Invoice struct {
	Number int
	Cents  int64
	Paid   bool
}

var pointerCents, valueCents int64

// lookupPointer's inv is moved to the heap: its address leaves the frame.
//
//go:noinline
func lookupPointer(number int) *Invoice {
	inv := Invoice{Number: number, Cents: int64(number) * 250}
	return &inv
}

// lookupValue copies 24 bytes into the caller's frame instead.
//
//go:noinline
func lookupValue(number int) Invoice {
	inv := Invoice{Number: number, Cents: int64(number) * 250}
	return inv
}

func main() {
	fmt.Println("pointer version, allocations per call:", testing.AllocsPerRun(1000, func() {
		inv := lookupPointer(42)
		pointerCents += inv.Cents
	}))
	fmt.Println("value version, allocations per call:  ", testing.AllocsPerRun(1000, func() {
		inv := lookupValue(42)
		valueCents += inv.Cents
	}))
	fmt.Println("both versions summed the same cents:", pointerCents == valueCents)
}
