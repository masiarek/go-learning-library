// Kata: an Average over a Number constraint, returning float64 whatever T is,
// and a MinMax over cmp.Ordered -- each called on a named type as well as a
// predeclared one.
//
//	go build a_type_parameter_needs_a_constraint_kata_go.go && ./a_type_parameter_needs_a_constraint_kata_go
package main

import (
	"cmp"
	"fmt"
)

type Number interface {
	~int | ~int64 | ~float64
}

// Average converts each value: float64(v) is allowed because every type in
// Number's set converts to float64.
func Average[T Number](values []T) float64 {
	if len(values) == 0 {
		return 0
	}
	var total float64
	for _, v := range values {
		total += float64(v)
	}
	return total / float64(len(values))
}

// MinMax needs < and >, so cmp.Ordered; it returns two values of T, not of
// float64, because the caller's type is the one that carries meaning.
func MinMax[T cmp.Ordered](values []T) (lo, hi T) {
	lo, hi = values[0], values[0]
	for _, v := range values[1:] {
		if v < lo {
			lo = v
		}
		if v > hi {
			hi = v
		}
	}
	return lo, hi
}

type Celsius float64

func main() {
	fmt.Println("Average of quantities:", Average([]int{4, 7, 10}))
	fmt.Println("Average of readings:  ", Average([]Celsius{21.5, 19, 23}))
	lo, hi := MinMax([]string{"pear", "apple", "quince"})
	fmt.Printf("MinMax of names:       %q %q\n", lo, hi)
	rlo, rhi := MinMax([]Celsius{21.5, 19, 23})
	fmt.Printf("MinMax of readings:    %v %v (%T)\n", rlo, rhi, rlo)
}
