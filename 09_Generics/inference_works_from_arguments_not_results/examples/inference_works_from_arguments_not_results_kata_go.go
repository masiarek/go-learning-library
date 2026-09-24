// Kata: a Reduce[T, U] called three ways -- fully inferred from its arguments,
// as a function value with both type arguments written out, and explicitly
// instantiated because a nil argument says nothing about U.
//
//	go build inference_works_from_arguments_not_results_kata_go.go && ./inference_works_from_arguments_not_results_kata_go
package main

import (
	"fmt"
	"strconv"
)

func Reduce[T, U any](values []T, start U, f func(U, T) U) U {
	acc := start
	for _, v := range values {
		acc = f(acc, v)
	}
	return acc
}

func main() {
	quantities := []int{4, 7, 10}

	// T from quantities, U from the untyped constant 0 (default type int).
	total := Reduce(quantities, 0, func(acc, q int) int { return acc + q })
	fmt.Printf("inferred:     total %d (%T)\n", total, total)

	// A function value: every type argument spelled out.
	join := Reduce[string, string]
	names := []string{"pear", "apple"}
	fmt.Printf("as a value:   %q\n", join(names, "", func(acc, n string) string { return acc + n + ";" }))

	// nil could be a []string, a map, a pointer... so U is written.
	labels := Reduce[int, []string](quantities, nil, func(acc []string, q int) []string {
		return append(acc, "qty-"+strconv.Itoa(q))
	})
	fmt.Printf("instantiated: %q\n", labels)
}
