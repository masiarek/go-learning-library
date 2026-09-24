// Kata: setField(target, name, value) sets a struct field by name through a
// pointer and returns an error, never a panic, for a target that is not a
// pointer to a struct, a field that does not exist, an unexported field, and
// a value of the wrong type.
//
//	go build reflect_sets_only_addressable_values_kata_go.go && ./reflect_sets_only_addressable_values_kata_go
package main

import (
	"fmt"
	"reflect"
)

type Order struct {
	Customer string
	Quantity int
	discount float64
}

func setField(target any, name string, value any) error {
	v := reflect.ValueOf(target)
	if v.Kind() != reflect.Pointer || v.Elem().Kind() != reflect.Struct {
		return fmt.Errorf("setField: need a pointer to a struct, got %s", v.Type())
	}
	f := v.Elem().FieldByName(name)
	if !f.IsValid() {
		return fmt.Errorf("setField: %s has no field %s", v.Elem().Type(), name)
	}
	if !f.CanSet() {
		return fmt.Errorf("setField: %s.%s is not settable (unexported)", v.Elem().Type(), name)
	}
	nv := reflect.ValueOf(value)
	if !nv.Type().AssignableTo(f.Type()) {
		return fmt.Errorf("setField: cannot assign %s to %s.%s (%s)", nv.Type(), v.Elem().Type(), name, f.Type())
	}
	f.Set(nv)
	return nil
}

func main() {
	order := Order{Customer: "Ada", Quantity: 1}
	fmt.Println(setField(order, "Quantity", 3))
	fmt.Println(setField(&order, "Weight", 3))
	fmt.Println(setField(&order, "discount", 0.1))
	fmt.Println(setField(&order, "Quantity", "three"))
	fmt.Println(setField(&order, "Quantity", 3), setField(&order, "Customer", "Ada Lovelace"))
	fmt.Printf("%+v\n", order)
}
