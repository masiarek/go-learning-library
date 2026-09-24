// Kata: an Equal for orders was written with reflect.DeepEqual. Count its
// allocations per call against == and against a hand-written method, on two
// variables the compiler cannot fold, and say which to keep.
//
//	go build reflection_costs_allocations_kata_go.go && ./reflection_costs_allocations_kata_go
package main

import (
	"fmt"
	"reflect"
	"testing"
)

type Order struct {
	ID       int
	Customer string
	Items    [3]string
}

func (o Order) Equal(p Order) bool {
	return o.ID == p.ID && o.Customer == p.Customer && o.Items == p.Items
}

var (
	left  = Order{ID: 7, Customer: "Ada", Items: [3]string{"lamp", "desk", "chair"}}
	right = Order{ID: 7, Customer: "Ada", Items: [3]string{"lamp", "desk", "chair"}}
	sink  bool
)

func main() {
	count := func(what string, f func()) { fmt.Printf("%-28s %v\n", what, testing.AllocsPerRun(100, f)) }
	count("reflect.DeepEqual(left, right)", func() { sink = reflect.DeepEqual(left, right) })
	count("left == right", func() { sink = left == right })
	count("left.Equal(right)", func() { sink = left.Equal(right) })
	fmt.Println("all three agree:", reflect.DeepEqual(left, right) == (left == right) && (left == right) == left.Equal(right))
	fmt.Println("keep: == (the type is comparable); DeepEqual is for slices and maps")
}
