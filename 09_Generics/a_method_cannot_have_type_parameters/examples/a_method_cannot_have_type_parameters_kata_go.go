// Kata: a fold over a Stack[T] into a summary of another type U. A method
// cannot introduce U, so the fold is written both ways a method cannot be: a
// top-level ReduceStack, and a Folder[T, U] type whose Fold method has both.
//
//	go build a_method_cannot_have_type_parameters_kata_go.go && ./a_method_cannot_have_type_parameters_kata_go
package main

import "fmt"

type Stack[T any] struct{ items []T }

func (s *Stack[T]) Push(v T) { s.items = append(s.items, v) }

// ReduceStack folds the items, bottom to top, into a U.
func ReduceStack[T, U any](s *Stack[T], start U, f func(U, T) U) U {
	acc := start
	for _, v := range s.items {
		acc = f(acc, v)
	}
	return acc
}

// Folder fixes the fold once; Fold then reads like the method that could not
// be written.
type Folder[T, U any] struct {
	start U
	f     func(U, T) U
}

func (r Folder[T, U]) Fold(s *Stack[T]) U { return ReduceStack(s, r.start, r.f) }

func main() {
	var quantities Stack[int]
	for _, q := range []int{4, 7, 10} {
		quantities.Push(q)
	}
	total := ReduceStack(&quantities, 0, func(acc, q int) int { return acc + q })
	fmt.Printf("ReduceStack: total quantity %d (%T)\n", total, total)

	var names Stack[string]
	names.Push("pear")
	names.Push("apple")
	joiner := Folder[string, string]{start: "", f: func(acc, n string) string {
		if acc == "" {
			return n
		}
		return acc + ", " + n
	}}
	fmt.Printf("Folder.Fold: %q (%T)\n", joiner.Fold(&names), joiner)

	count := Folder[string, int]{start: 0, f: func(acc int, _ string) int { return acc + 1 }}
	fmt.Println("Folder.Fold: count", count.Fold(&names))
}
