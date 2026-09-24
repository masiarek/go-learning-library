// A method with a pointer receiver belongs to the method set of *T only; a
// method with a value receiver belongs to both T and *T. The compiler writes
// (&c).Increment() for you when c is addressable -- a variable, a slice
// element, a field of one of those -- which is why the pointer method seems
// to be on the value until the value is somewhere it cannot take the address
// of (a map element, a value inside an interface): those are compile errors,
// recorded by a_pointer_receiver_not_in_the_method_set_sh.sh.
//
//	go build a_pointer_receiver_changes_the_method_set_go.go && ./a_pointer_receiver_changes_the_method_set_go
package main

import (
	"fmt"
	"reflect"
	"strings"
)

// Counter counts orders. Value reads a copy; Increment must change the
// original, so its receiver is a pointer. Reset has a value receiver by
// mistake: it resets a copy and leaves the counter as it was.
type Counter struct{ orders int }

func (c Counter) Value() int  { return c.orders }
func (c *Counter) Increment() { c.orders++ }
func (c Counter) Reset()      { c.orders = 0 }

// Incrementer is satisfied by *Counter and not by Counter.
type Incrementer interface{ Increment() }

// Valuer is satisfied by both Counter and *Counter.
type Valuer interface{ Value() int }

// methods lists the exported methods reflect sees in a type's method set,
// in the sorted order reflect keeps them in.
func methods(t reflect.Type) string {
	names := make([]string, 0, t.NumMethod())
	for i := range t.NumMethod() {
		names = append(names, t.Method(i).Name)
	}
	return "[" + strings.Join(names, " ") + "]"
}

func main() {
	var c Counter
	fmt.Println("method set of Counter: ", methods(reflect.TypeOf(c)))
	fmt.Println("method set of *Counter:", methods(reflect.TypeOf(&c)))

	c.Increment() // c is addressable: the compiler calls (&c).Increment()
	c.Increment()
	fmt.Println("after two c.Increment() calls, c.Value() =", c.Value())

	var v Valuer = c         // a Counter value satisfies Valuer: Value has a value receiver
	var inc Incrementer = &c // only *Counter satisfies Incrementer
	inc.Increment()
	fmt.Println("after inc.Increment() through *Counter, c.Value() =", c.Value(), "; the Valuer holds a copy taken earlier:", v.Value())

	c.Reset()
	fmt.Println("after c.Reset() with a value receiver, c.Value() =", c.Value(), "(a copy was reset, not c)")

	// A slice element is addressable, so the pointer method works on it in place.
	counters := []Counter{{}, {}}
	counters[0].Increment()
	fmt.Println("counters[0].Increment() on a slice element: counters[0].Value() =", counters[0].Value())

	// A map element is not addressable -- so a map of pointers is the usual shape.
	byQueue := map[string]*Counter{"web": {}}
	byQueue["web"].Increment()
	fmt.Println("byQueue[\"web\"].Increment() through a *Counter in the map:", byQueue["web"].Value())

	// The same rule, checked at run time on interface values.
	_, ok := any(c).(Incrementer)
	fmt.Println("does any(c) hold an Incrementer?  ", ok)
	_, ok = any(&c).(Incrementer)
	fmt.Println("does any(&c) hold an Incrementer? ", ok)
	_, ok = any(c).(Valuer)
	fmt.Println("does any(c) hold a Valuer?        ", ok)
}
