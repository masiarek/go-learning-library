// Kata: an order index has lookupTyped, written the typed-nil way, so every
// caller's err != nil fires even for an order that exists. Write diagnose(err)
// that returns "nil", "typed nil holding <type>" or "error: <message>", run
// it over the broken lookup and the fixed one, and print the verdicts.
//
//	go build a_nil_pointer_in_an_interface_is_not_nil_kata_go.go && ./a_nil_pointer_in_an_interface_is_not_nil_kata_go
package main

import (
	"fmt"
	"reflect"
)

type Order struct {
	ID    int
	Total int
}

type NotFoundError struct{ ID int }

func (e *NotFoundError) Error() string { return fmt.Sprintf("order %d not found", e.ID) }

var index = map[int]Order{7: {ID: 7, Total: 120}}

// lookupTyped declares the concrete pointer up front and returns it on both paths.
func lookupTyped(id int) (Order, error) {
	var notFound *NotFoundError
	order, ok := index[id]
	if !ok {
		notFound = &NotFoundError{ID: id}
	}
	return order, notFound
}

// lookup returns a literal nil when the order exists.
func lookup(id int) (Order, error) {
	order, ok := index[id]
	if !ok {
		return Order{}, &NotFoundError{ID: id}
	}
	return order, nil
}

func diagnose(err error) string {
	if err == nil {
		return "nil"
	}
	if v := reflect.ValueOf(err); v.Kind() == reflect.Pointer && v.IsNil() {
		return fmt.Sprintf("typed nil holding %T", err)
	}
	return "error: " + err.Error()
}

func main() {
	for _, id := range []int{7, 8} {
		_, err := lookupTyped(id)
		fmt.Printf("lookupTyped(%d): err != nil is %-5t  %s\n", id, err != nil, diagnose(err))
	}
	for _, id := range []int{7, 8} {
		_, err := lookup(id)
		fmt.Printf("lookup(%d):      err != nil is %-5t  %s\n", id, err != nil, diagnose(err))
	}
}
