// A reflect.Value can change the variable it came from only when it is
// addressable and was not reached through an unexported field. ValueOf(x) is
// a copy and cannot be set; ValueOf(&x).Elem() is the variable itself.
//
//	go build reflect_sets_only_addressable_values_go.go && ./reflect_sets_only_addressable_values_go
package main

import (
	"fmt"
	"reflect"
)

type Account struct {
	Owner   string
	Balance int
	pin     int // unexported: readable through reflect, never settable
}

func main() {
	balance := 100
	fmt.Println("ValueOf(balance).CanSet():        ", reflect.ValueOf(balance).CanSet())
	fmt.Println("ValueOf(&balance).Elem().CanSet():", reflect.ValueOf(&balance).Elem().CanSet())
	reflect.ValueOf(&balance).Elem().SetInt(250)
	fmt.Println("after SetInt through the pointer:  balance =", balance)
	fmt.Println("SetInt on the copy:      ", panics(func() { reflect.ValueOf(balance).SetInt(1) }))

	acct := Account{Owner: "Ada", Balance: 100, pin: 1234}
	v := reflect.ValueOf(&acct).Elem()
	pin := v.FieldByName("pin")
	fmt.Printf("pin: CanAddr %t, CanSet %t, Int() %d\n", pin.CanAddr(), pin.CanSet(), pin.Int())
	fmt.Println("SetInt on unexported:    ", panics(func() { pin.SetInt(0) }))
	fmt.Println("Interface on unexported: ", panics(func() { _ = pin.Interface() }))

	v.FieldByName("Owner").SetString("Ada Lovelace")
	v.FieldByName("Balance").SetInt(175)
	fmt.Printf("after setting by name: %+v\n", acct)
	fmt.Println("FieldByName(\"Missing\").IsValid():", v.FieldByName("Missing").IsValid())
	fmt.Println("Set a string into an int:", panics(func() { v.FieldByName("Balance").Set(reflect.ValueOf("lots")) }))

	// A map element is not addressable either; SetMapIndex is the way in.
	limits := map[string]int{"Ada": 500}
	fmt.Println("MapIndex(...).CanSet():  ", reflect.ValueOf(limits).MapIndex(reflect.ValueOf("Ada")).CanSet())
	reflect.ValueOf(limits).SetMapIndex(reflect.ValueOf("Ada"), reflect.ValueOf(750))
	fmt.Println("after SetMapIndex:", limits)

	// reflect.New: a pointer to a fresh zero value, whose Elem is settable.
	p := reflect.New(reflect.TypeOf(Account{}))
	fmt.Printf("reflect.New: %s, Elem().CanSet() %t\n", p.Type(), p.Elem().CanSet())
	p.Elem().FieldByName("Owner").SetString("Grace")
	fmt.Printf("  %+v\n", p.Interface())

	// MakeSlice and Append build a slice of a type known only at run time.
	owners := reflect.MakeSlice(reflect.TypeOf([]string{}), 0, 2)
	owners = reflect.Append(owners, reflect.ValueOf("Ada"), reflect.ValueOf("Grace"))
	fmt.Printf("MakeSlice+Append: %v, len %d, cap %d, type %s\n", owners, owners.Len(), owners.Cap(), owners.Type())
	names := owners.Interface().([]string)
	fmt.Println("  back as []string:", names, len(names))
}

// panics runs f and reports what it panicked with, or "no panic".
func panics(f func()) (msg any) {
	defer func() { msg = recover() }()
	f()
	return "no panic"
}
