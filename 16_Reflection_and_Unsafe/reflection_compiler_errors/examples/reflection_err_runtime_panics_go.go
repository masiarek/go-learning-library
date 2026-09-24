// The compiler checks that a reflect.Value is a reflect.Value; what Kind it
// holds is known only at run time, so a method called on the wrong Kind, or
// a Field index past the end, is a panic. Each one here is recovered and
// printed. Every message is from package reflect itself, except the last.
//
//	go build reflection_err_runtime_panics_go.go && ./reflection_err_runtime_panics_go
package main

import (
	"fmt"
	"reflect"
)

type Invoice struct {
	Number string
	Amount float64
}

func main() {
	count := 3
	inv := Invoice{Number: "INV-7", Amount: 12.5}
	try("Field(0) on an int", func() { reflect.ValueOf(count).Field(0) })
	try("Field(2) on a 2-field struct", func() { reflect.ValueOf(inv).Field(2) })
	try("Int() on a string", func() { reflect.ValueOf(inv.Number).Int() })
	try("NumField() on an int Type", func() { reflect.TypeOf(count).NumField() })
	try("Elem() on an int", func() { reflect.ValueOf(count).Elem() })
	try("Elem() on an int Type", func() { reflect.TypeOf(count).Elem() })
	try("Call() on an int", func() { reflect.ValueOf(count).Call(nil) })
	try("Type() on the zero Value", func() { reflect.ValueOf(nil).Type() })
	try("Kind() on the zero Value", func() {
		fmt.Printf("%-32s no panic: Kind is %s\n", "Kind() on the zero Value", reflect.ValueOf(nil).Kind())
	})
	try("TypeOf(nil) is nil, so .Kind()", func() { reflect.TypeOf(nil).Kind() })
}

// try runs f and prints what it panicked with.
func try(what string, f func()) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("%-32s panic: %v\n", what, r)
		}
	}()
	f()
}
