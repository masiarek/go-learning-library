// Kata: parts to reorder in alphabetical order out of a map, the columns of a
// CSV header counted without building a slice, and orders in batches of
// three -- all with the standard library's iterators.
//
//	go build slices_and_maps_have_iterators_kata_go.go && ./slices_and_maps_have_iterators_kata_go
package main

import (
	"fmt"
	"maps"
	"slices"
	"strings"
)

func main() {
	stock := map[string]int{"bolt": 40, "nut": 4, "washer": 7, "screw": 12, "rivet": 2}
	fmt.Println("-- parts with fewer than 10 left, in alphabetical order")
	for _, part := range slices.Sorted(maps.Keys(stock)) {
		if stock[part] < 10 {
			fmt.Printf("%s (%d left)\n", part, stock[part])
		}
	}

	fmt.Println("-- columns of a CSV header, counted without a slice")
	columns := 0
	for column := range strings.SplitSeq("order,customer,part,quantity", ",") {
		columns++
		fmt.Printf("column %d: %s\n", columns, column)
	}
	fmt.Println("columns:", columns)

	fmt.Println("-- orders in batches of three")
	orders := []string{"order-1", "order-2", "order-3", "order-4", "order-5", "order-6", "order-7"}
	for batch := range slices.Chunk(orders, 3) {
		fmt.Printf("batch of %d: %s .. %s\n", len(batch), batch[0], batch[len(batch)-1])
	}
}
