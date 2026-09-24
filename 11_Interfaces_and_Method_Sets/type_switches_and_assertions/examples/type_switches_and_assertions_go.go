// A type assertion x.(T) asks whether the dynamic type of x is T -- or, when
// T is an interface, whether that dynamic type has T's methods. The two-value
// form answers with ok; the one-value form panics with the runtime's
// "interface conversion" message. A type switch does the same over several
// cases: in a single-type case the bound variable has that type, in a case
// listing several types (or in default) it keeps the interface type, and the
// variable shadows any outer one of the same name.
//
//	go build type_switches_and_assertions_go.go && ./type_switches_and_assertions_go
package main

import (
	"errors"
	"fmt"
	"reflect"
)

type Order struct{ ID int }

type Invoice struct{ ID int }

func (i Invoice) String() string { return fmt.Sprintf("invoice %d", i.ID) }

// describe classifies a value with one type switch. staticType reports the
// type the compiler gave the bound variable x in that case.
func describe(v any) string {
	switch x := v.(type) {
	case nil:
		return "nil: no dynamic type at all"
	case int:
		return fmt.Sprintf("int %d            (x has static type %s)", x, staticType(&x))
	case int8, int16, int32, int64:
		return fmt.Sprintf("a sized int %v    (x has static type %s)", x, staticType(&x))
	case fmt.Stringer:
		return fmt.Sprintf("a Stringer: %q (x has static type %s)", x.String(), staticType(&x))
	case error:
		return "an error: " + x.Error()
	default:
		return fmt.Sprintf("something else: %T (x has static type %s)", x, staticType(&x))
	}
}

func staticType[T any](p *T) string { return reflect.TypeOf(p).Elem().String() }

func panicOf(f func()) (value any) {
	defer func() { value = recover() }()
	f()
	return "none"
}

func main() {
	for _, v := range []any{nil, 42, int64(42), Invoice{ID: 3}, errors.New("late"), Order{ID: 9}} {
		fmt.Println("describe:", describe(v))
	}

	var x any = "order-17"
	s, ok := x.(string)
	fmt.Printf("x.(string) two-value: %q, %t\n", s, ok)
	n, ok := x.(int)
	fmt.Printf("x.(int)    two-value: %d, %t (the zero value, and false)\n", n, ok)
	fmt.Println("x.(int)    one-value panics:", panicOf(func() { _ = x.(int) }))

	var nothing any
	fmt.Println("nil.(int)  one-value panics:", panicOf(func() { _ = nothing.(int) }))

	// Asserting to another interface checks the dynamic type's method set at run time.
	var order any = Order{ID: 9}
	_, ok = order.(fmt.Stringer)
	fmt.Println("Order as fmt.Stringer, two-value:", ok)
	fmt.Println("Order as fmt.Stringer, one-value panics:", panicOf(func() { _ = order.(fmt.Stringer) }))
	var str fmt.Stringer = Invoice{ID: 3}
	fmt.Println("fmt.Stringer holding Invoice, asserted to *Invoice, panics:", panicOf(func() { _ = str.(*Invoice) }))

	// switch v := x.(type) declares a new v for the switch; the outer v is untouched.
	v := "outer"
	switch v := x.(type) {
	case string:
		v += " (changed inside the switch)"
		fmt.Println("inside:  v =", v)
	}
	fmt.Println("outside: v =", v)
}
