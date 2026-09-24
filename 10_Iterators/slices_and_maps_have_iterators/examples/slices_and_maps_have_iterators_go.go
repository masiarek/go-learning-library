// The standard library's iterators: slices.Values, All, Backward, Collect and
// Chunk; maps.Keys, Values, All and Collect, with slices.Sorted as the way to
// get a fixed order out of a map; strings.SplitSeq and Lines, bytes.Lines.
// Every line printed here is in an order that cannot vary.
//
//	go build slices_and_maps_have_iterators_go.go && ./slices_and_maps_have_iterators_go
package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"iter"
	"maps"
	"slices"
	"strings"
)

// LinesOf reads r line by line. It is a single-use iterator: r cannot be
// rewound, so a second range over it finds nothing. strings.Lines is
// documented as single-use too, and the program checks that.
func LinesOf(r io.Reader) iter.Seq[string] {
	return func(yield func(string) bool) {
		scanner := bufio.NewScanner(r)
		for scanner.Scan() {
			if !yield(scanner.Text()) {
				return
			}
		}
	}
}

func main() {
	readings := []int{21, 19, 23}
	fmt.Println("-- slices")
	for r := range slices.Values(readings) {
		fmt.Println("Values:", r)
	}
	for i, r := range slices.All(readings) {
		fmt.Println("All:", i, r)
	}
	for i, r := range slices.Backward(readings) {
		fmt.Println("Backward:", i, r)
	}
	doubled := func(yield func(int) bool) {
		for _, r := range readings {
			if !yield(2 * r) {
				return
			}
		}
	}
	fmt.Println("Collect:", slices.Collect(doubled))
	for batch := range slices.Chunk([]string{"order-1", "order-2", "order-3", "order-4", "order-5"}, 2) {
		fmt.Println("Chunk:", batch)
	}

	fmt.Println("-- maps: a map iterator has no fixed order, so sort first")
	stock := map[string]int{"bolt": 40, "nut": 12, "washer": 7}
	fmt.Println("Sorted(Keys):", slices.Sorted(maps.Keys(stock)))
	fmt.Println("Sorted(Values):", slices.Sorted(maps.Values(stock)))
	for _, part := range slices.Sorted(maps.Keys(stock)) {
		fmt.Printf("%s: %d\n", part, stock[part])
	}
	copied := maps.Collect(maps.All(stock))
	fmt.Println("Collect(All) equal to the original:", maps.Equal(stock, copied))

	fmt.Println("-- strings and bytes")
	for field := range strings.SplitSeq("bolt,nut,,washer", ",") {
		fmt.Printf("SplitSeq: %q\n", field)
	}
	for line := range strings.Lines("first\nsecond\nthird") {
		fmt.Printf("Lines: %q\n", line)
	}
	for line := range bytes.Lines([]byte("first\r\nsecond\n")) {
		fmt.Printf("bytes.Lines: %q\n", line)
	}

	fmt.Println("-- reusable, and single-use")
	values := slices.Values(readings)
	fmt.Printf("slices.Values, twice: %v %v\n", slices.Collect(values), slices.Collect(values))
	text := "first\nsecond"
	lines := strings.Lines(text)
	fmt.Printf("strings.Lines, twice: %q %q\n", slices.Collect(lines), slices.Collect(lines))
	fromReader := LinesOf(strings.NewReader(text))
	fmt.Printf("LinesOf a reader, twice: %q %q\n", slices.Collect(fromReader), slices.Collect(fromReader))
}
