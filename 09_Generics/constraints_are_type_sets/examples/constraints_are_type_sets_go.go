// A constraint is an interface read as a set of types. A union lists the set;
// a method narrows it to the types that have the method; and since Go 1.20
// comparable admits interface types too -- whose == can panic at run time,
// depending on the dynamic types being compared.
//
//	go build constraints_are_type_sets_go.go && ./constraints_are_type_sets_go
package main

import "fmt"

// Key is a pure type set: every type built on int or on string.
type Key interface {
	~int | ~string
}

func Join[T Key](keys []T) string {
	out := ""
	for _, k := range keys {
		out += fmt.Sprint(k) + ";"
	}
	return out
}

// Quantity is a type set AND a method: the numeric types that also have Unit.
type Quantity interface {
	~int | ~float64
	Unit() string
}

type Grams int

func (Grams) Unit() string { return "g" }

type Litres float64

func (Litres) Unit() string { return "L" }

// Total uses + (from the union) and Unit (from the method).
func Total[T Quantity](values []T) string {
	var total T
	for _, v := range values {
		total += v
	}
	return fmt.Sprintf("%v %s", total, total.Unit())
}

func Index[T comparable](values []T, want T) int {
	for i, v := range values {
		if v == want {
			return i
		}
	}
	return -1
}

type Set[T comparable] map[T]struct{}

// outcome runs f and reports what it returned or what it panicked with.
func outcome(f func() any) string {
	var result any
	func() {
		defer func() {
			if r := recover(); r != nil {
				result = fmt.Sprint("panic: ", r)
			}
		}()
		result = f()
	}()
	return fmt.Sprint(result)
}

func main() {
	fmt.Println("Join over ~int | ~string:", Join([]int{7, 12}), Join([]string{"pear", "apple"}))
	fmt.Println("Total over a union with a method:", Total([]Grams{250, 125}), "|", Total([]Litres{1.5, 0.25}))

	// comparable, instantiated with the interface type any (Go 1.20+).
	fmt.Println("Index([]any{1, \"a\", 2}, 2) =", outcome(func() any { return Index([]any{1, "a", 2}, 2) }))
	fmt.Println("Index([]any{[]int{1}, 2}, 2) =", outcome(func() any { return Index([]any{[]int{1}, 2}, 2) }))
	fmt.Println("Index([]any{[]int{1}}, any([]int{1})) =", outcome(func() any { return Index([]any{[]int{1}}, any([]int{1})) }))
	fmt.Println("Set[any] with a []int key:", outcome(func() any {
		seen := Set[any]{}
		seen[[]int{1}] = struct{}{}
		return len(seen)
	}))
}
