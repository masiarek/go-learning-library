// Kata: a pipeline keeps sensor readings in a []any. Measure with
// testing.AllocsPerRun how many heap allocations storing one Reading value
// costs against storing a *Reading, print both counts with the sizes of a
// Reading and of an any, and print which of the two you would store.
//
//	go build an_interface_is_two_words_kata_go.go && ./an_interface_is_two_words_kata_go
package main

import (
	"fmt"
	"testing"
	"unsafe"
)

type Reading struct {
	Sensor  int
	Celsius float64
	Tick    int
}

//go:noinline
func readingValue(r Reading) Reading { return r }

func main() {
	slot := make([]any, 1)
	reading := readingValue(Reading{Sensor: 3, Celsius: 21.5, Tick: 40})
	pointer := &reading

	byValue := testing.AllocsPerRun(1000, func() { slot[0] = reading })
	byPointer := testing.AllocsPerRun(1000, func() { slot[0] = pointer })

	fmt.Println("unsafe.Sizeof(Reading) =", unsafe.Sizeof(reading), " unsafe.Sizeof(any) =", unsafe.Sizeof(slot[0]))
	fmt.Println("allocations per store of a Reading: ", byValue)
	fmt.Println("allocations per store of a *Reading:", byPointer)
	switch {
	case byPointer < byValue:
		fmt.Println("store *Reading: the data word holds the pointer, so nothing is copied to the heap per store")
	default:
		fmt.Println("store Reading: no difference measured")
	}
}
