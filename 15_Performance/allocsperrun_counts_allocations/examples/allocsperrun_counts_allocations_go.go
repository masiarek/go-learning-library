// testing.AllocsPerRun counts the heap allocations one call of a function
// makes, from an ordinary program: no test file, no benchmark, and a whole
// number that is the same on every run. Four pairs of ways to do the same
// thing, and the count for each.
//
//	go build allocsperrun_counts_allocations_go.go && ./allocsperrun_counts_allocations_go
package main

import (
	"fmt"
	"strconv"
	"strings"
	"testing"
)

var fields = []string{
	"customer=acme-industries",
	"item=steel-bracket-40mm",
	"quantity=1200",
	"warehouse=rotterdam-east",
}

// Values read from a slice at run time, so the compiler cannot treat them as
// constants (a constant boxed into an interface costs nothing: see the last line).
var quantities = []int{42, 255, 256, 4096}

// The results are kept in package variables so that no call can be optimised
// away as unused.
var (
	line  string
	items []int
	boxed any
)

func main() {
	report := func(what string, f func()) {
		fmt.Printf("%-42s %v\n", what, testing.AllocsPerRun(200, f))
	}

	report("line += field, 4 fields", func() {
		line = "order:"
		for _, f := range fields {
			line += f + ";"
		}
	})
	report("strings.Builder with Grow, 4 fields", func() {
		var b strings.Builder
		b.Grow(128)
		b.WriteString("order:")
		for _, f := range fields {
			b.WriteString(f)
			b.WriteByte(';')
		}
		line = b.String()
	})

	big, small := quantities[3], quantities[0]
	report("fmt.Sprintf(\"%d\", 4096)", func() { line = fmt.Sprintf("%d", big) })
	report("strconv.Itoa(4096)", func() { line = strconv.Itoa(big) })
	report("strconv.Itoa(42)", func() { line = strconv.Itoa(small) })

	report("append to a nil slice, 10 ints", func() {
		var s []int
		for i := range 10 {
			s = append(s, i)
		}
		items = s
	})
	report("make([]int, 0, 10), then 10 appends", func() {
		s := make([]int, 0, 10)
		for i := range 10 {
			s = append(s, i)
		}
		items = s
	})

	for _, q := range quantities {
		report(fmt.Sprintf("boxed = %d (an int into any)", q), func() { boxed = q })
	}
	report("boxed = 4096 (the constant)", func() { boxed = 4096 })
}
