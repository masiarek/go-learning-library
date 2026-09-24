// Type inference reads the arguments of a call. It does not read what the
// result is assigned to, so a function whose type parameter appears only in
// its result is instantiated by hand: Zero[int](). Since Go 1.21 a generic
// function passed as an argument, or assigned to a variable of function type,
// is inferred too.
//
//	go build inference_works_from_arguments_not_results_go.go && ./inference_works_from_arguments_not_results_go
package main

import (
	"cmp"
	"fmt"
	"slices"
	"strconv"
	"strings"
)

func Map[T, U any](in []T, f func(T) U) []U {
	out := make([]U, 0, len(in))
	for _, v := range in {
		out = append(out, f(v))
	}
	return out
}

func Identity[T any](v T) T { return v }

// Zero's T appears in the result only: no argument can name it.
func Zero[T any]() T {
	var zero T
	return zero
}

func Twice[T ~int | ~float64](v T) T { return v * 2 }

func Larger[T ~int | ~float64](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func main() {
	names := []string{"pear", "apple"}

	// 1. From the arguments: T = string from names, U = string from ToUpper.
	fmt.Println("1.", Map(names, strings.ToUpper))

	// 2. Go 1.21: a generic function passed as an argument is inferred as well.
	fmt.Println("2.", Map(names, Identity))

	// 3. Go 1.21: assigned to a variable of function type, Identity is inferred
	// from that type.
	var keep func(string) string = Identity
	fmt.Println("3.", keep("kept"))

	// 4. Nothing in Zero's arguments names T: instantiate it explicitly.
	fmt.Printf("4. %q %d %v\n", Zero[string](), Zero[int](), Zero[[]int]() == nil)

	// 5. A function value needs the full instantiation ...
	toLabel := Map[int, string]
	fmt.Println("5.", toLabel([]int{7, 12}, strconv.Itoa))
	// ... but inside a call a partial one is enough; U comes from Itoa.
	fmt.Println("5.", Map[int]([]int{7, 12}, strconv.Itoa))

	// 6. Untyped constants: the default type, or, since 1.21, the kind that
	// holds both, as 3 + 2.5 would.
	fmt.Printf("6. %T %T %T\n", Twice(3), Twice(3.5), Larger(3, 2.5))

	// 7. The standard library's own case: cmp.Compare is generic, and
	// slices.SortFunc instantiates it from the slice's element type.
	slices.SortFunc(names, cmp.Compare)
	fmt.Println("7.", names)
}
