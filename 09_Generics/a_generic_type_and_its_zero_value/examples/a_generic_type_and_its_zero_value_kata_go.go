// Kata: a Queue[T] with Push, Pop() (T, bool) and Len, drained past empty so
// that the zero value and the false show, and printed with %T.
//
//	go build a_generic_type_and_its_zero_value_kata_go.go && ./a_generic_type_and_its_zero_value_kata_go
package main

import "fmt"

type Queue[T any] struct{ items []T }

func (q *Queue[T]) Push(v T) { q.items = append(q.items, v) }

func (q *Queue[T]) Len() int { return len(q.items) }

// Pop takes from the front; on an empty queue it returns T's zero value and false.
func (q *Queue[T]) Pop() (T, bool) {
	if len(q.items) == 0 {
		var zero T
		return zero, false
	}
	front := q.items[0]
	q.items = q.items[1:]
	return front, true
}

type Order struct {
	ID  int
	Qty int
}

func main() {
	var orders Queue[Order]
	orders.Push(Order{ID: 7, Qty: 2})
	orders.Push(Order{ID: 12, Qty: 5})
	fmt.Printf("%T holds %d\n", orders, orders.Len())
	for range 3 {
		o, ok := orders.Pop()
		fmt.Printf("Pop: %+v, ok = %t\n", o, ok)
	}

	var names Queue[string]
	names.Push("pear")
	n, ok := names.Pop()
	fmt.Printf("%T: %q, ok = %t; then ", names, n, ok)
	n, ok = names.Pop()
	fmt.Printf("%q, ok = %t\n", n, ok)
}
