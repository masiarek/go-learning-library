// A type parameter is only as capable as its constraint. Under any, a T can be
// stored and passed on and nothing more; cmp.Ordered unlocks < and >,
// comparable unlocks ==, and a ~int term admits every type whose underlying
// type is int, not just int itself.
//
//	go build a_type_parameter_needs_a_constraint_go.go && ./a_type_parameter_needs_a_constraint_go
package main

import (
	"cmp"
	"fmt"
	"math"
)

// Max needs >, so its constraint is cmp.Ordered: every integer, float and
// string type, and every named type built on one of them.
func Max[T cmp.Ordered](a, b T) T {
	if a > b {
		return a
	}
	return b
}

// Number is a type set written with ~ terms: int, int64, float64, and every
// named type whose underlying type is one of them.
type Number interface {
	~int | ~int64 | ~float64
}

// Sum needs + and a zero value of T. Both come from Number: every type in the
// set has them.
func Sum[T Number](values []T) T {
	var total T
	for _, v := range values {
		total += v
	}
	return total
}

// Contains needs ==, which comparable provides.
func Contains[T comparable](values []T, want T) bool {
	for _, v := range values {
		if v == want {
			return true
		}
	}
	return false
}

// Celsius is a named type whose underlying type is float64. Number admits it
// because its terms carry ~; cmp.Ordered admits it for the same reason.
type Celsius float64

func main() {
	fmt.Println("Max(3, 7) =", Max(3, 7))
	fmt.Println("Max(\"pear\", \"apple\") =", Max("pear", "apple"))
	fmt.Println("Max(Celsius(21), Celsius(19)) =", Max(Celsius(21), Celsius(19)))
	fmt.Println("Max(2.5, NaN) =", Max(2.5, math.NaN()), " Max(NaN, 2.5) =", Max(math.NaN(), 2.5), " builtin max(2.5, NaN) =", max(2.5, math.NaN()))

	fmt.Println("Sum([]int{1, 2, 3}) =", Sum([]int{1, 2, 3}))
	fmt.Println("Sum([]float64{0.5, 0.25}) =", Sum([]float64{0.5, 0.25}))
	fmt.Println("Sum([]Celsius{21.5, 19}) =", Sum([]Celsius{21.5, 19}))

	fmt.Println("Contains(readings, 19) =", Contains([]int{21, 19, 23}, 19))
	fmt.Println("Contains(names, \"kiwi\") =", Contains([]string{"pear", "apple"}, "kiwi"))
}
