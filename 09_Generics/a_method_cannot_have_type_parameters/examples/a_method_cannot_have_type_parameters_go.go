// A method's only type parameters are its receiver's. A Stack[T] method may
// use T; to turn a Stack[T] into a Stack[U] a second parameter is needed, and
// it goes on a top-level function -- or on a second generic type, whose method
// then has both.
//
//	go build a_method_cannot_have_type_parameters_go.go && ./a_method_cannot_have_type_parameters_go
package main

import (
	"fmt"
	"strconv"
)

type Stack[T any] struct{ items []T }

func (s *Stack[T]) Push(v T) { s.items = append(s.items, v) }

// Items uses T, the receiver's parameter -- the one thing a method may use.
func (s *Stack[T]) Items() []T { return s.items }

// Workaround 1: a top-level generic function that takes the receiver as its
// first argument. T and U are both inferred at the call.
func MapStack[T, U any](s *Stack[T], f func(T) U) *Stack[U] {
	out := &Stack[U]{}
	for _, v := range s.items {
		out.Push(f(v))
	}
	return out
}

// Workaround 2: a generic type that carries both parameters, so that its
// method can use both. The price is that U is fixed when the Converter is
// made, not at each call.
type Converter[T, U any] struct{ f func(T) U }

func (c Converter[T, U]) Convert(s *Stack[T]) *Stack[U] {
	return MapStack(s, c.f)
}

func main() {
	var orders Stack[int]
	orders.Push(7)
	orders.Push(12)

	labels := MapStack(&orders, func(n int) string { return "order-" + strconv.Itoa(n) })
	fmt.Printf("MapStack:  %T -> %T %q\n", &orders, labels, labels.Items())

	halve := Converter[int, float64]{f: func(n int) float64 { return float64(n) / 2 }}
	halves := halve.Convert(&orders)
	fmt.Printf("Converter: %T -> %T %v\n", halve, halves, halves.Items())
}
