// A generic type is a template for types: Stack[int] and Stack[string] are two
// distinct types, and %T prints each with its type argument. Inside a method
// the zero value of T is spelled var zero T, or *new(T), and a Pop that may
// have nothing to return says so with a second result.
//
//	go build a_generic_type_and_its_zero_value_go.go && ./a_generic_type_and_its_zero_value_go
package main

import "fmt"

type Stack[T any] struct{ items []T }

func (s *Stack[T]) Push(v T) { s.items = append(s.items, v) }

// Pop returns the top item, or T's zero value and false when there is none.
func (s *Stack[T]) Pop() (T, bool) {
	if len(s.items) == 0 {
		var zero T
		return zero, false
	}
	top := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return top, true
}

// Peek spells the zero value the other way: new(T) is a *T to a zeroed T.
func (s *Stack[T]) Peek() (T, bool) {
	if len(s.items) == 0 {
		return *new(T), false
	}
	return s.items[len(s.items)-1], true
}

// Set needs == on its keys, so T is comparable, not any.
type Set[T comparable] map[T]struct{}

func (s Set[T]) Add(v T)      { s[v] = struct{}{} }
func (s Set[T]) Has(v T) bool { _, ok := s[v]; return ok }

type Pair[K comparable, V any] struct {
	Key K
	Val V
}

func main() {
	var invoices Stack[string]
	invoices.Push("inv-1")
	invoices.Push("inv-2")
	for range 3 {
		v, ok := invoices.Pop()
		fmt.Printf("Pop: %q, ok = %t\n", v, ok)
	}

	var readings Stack[float64]
	v, ok := readings.Peek()
	fmt.Printf("Peek on empty Stack[float64]: %v, ok = %t\n", v, ok)
	var owners Stack[*string]
	p, ok := owners.Pop()
	fmt.Printf("Pop on empty Stack[*string]: %v, ok = %t\n", p, ok)

	tags := Set[string]{}
	tags.Add("paid")
	fmt.Printf("Set: Has(\"paid\") = %t, Has(\"void\") = %t, len = %d\n", tags.Has("paid"), tags.Has("void"), len(tags))

	fmt.Printf("%%T: %T, %T, %T, %T\n", invoices, &readings, tags, Pair[string, float64]{})
	fmt.Printf("%%T: %T, %T\n", Stack[[]byte]{}, Stack[Stack[int]]{})
	fmt.Printf("%%v of a zero Stack[int]: %v, %%+v: %+v\n", Stack[int]{}, Stack[int]{})
}
