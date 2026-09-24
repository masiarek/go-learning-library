// An interface value is two machine words: a type word and a data word. For
// the empty interface the type word points at the dynamic type's descriptor;
// for an interface with methods it points at an itab that carries the type
// and the method table. The data word is a pointer to the value -- or, for
// a value that is itself a pointer, the pointer itself. This program reads
// the two words through unsafe and reports what they hold, never the numbers.
//
//	go build an_interface_is_two_words_go.go && ./an_interface_is_two_words_go
package main

import (
	"fmt"
	"unsafe"
)

type Order struct{ ID, Qty int }

type ValidationError struct{ Field string }

func (e *ValidationError) Error() string { return "invalid " + e.Field }

// words is the layout of every interface value in the runtime: two pointers.
type words struct {
	typ  unsafe.Pointer
	data unsafe.Pointer
}

func wordsOf(p unsafe.Pointer) words { return *(*words)(p) }

func panicOf(f func()) (value any) {
	defer func() { value = recover() }()
	f()
	return "none"
}

func main() {
	var empty any
	var err error
	fmt.Println("unsafe.Sizeof(any)     =", unsafe.Sizeof(empty))
	fmt.Println("unsafe.Sizeof(error)   =", unsafe.Sizeof(err))
	fmt.Println("unsafe.Sizeof(uintptr) =", unsafe.Sizeof(uintptr(0)), "-- so an interface is two words")

	w := wordsOf(unsafe.Pointer(&empty))
	fmt.Println("nil any:              type word nil?", w.typ == nil, " data word nil?", w.data == nil)

	quantity := 7
	var boxed any = quantity
	w = wordsOf(unsafe.Pointer(&boxed))
	fmt.Println("any holding int 7:    type word nil?", w.typ == nil, " data word points at a 7?", *(*int)(w.data) == 7, " at the variable quantity?", w.data == unsafe.Pointer(&quantity))
	quantity = 8
	fmt.Println("  after quantity = 8, the any still holds", boxed, "-- the data word points at a copy")

	order := &Order{ID: 1, Qty: 2}
	var boxedPointer any = order
	w = wordsOf(unsafe.Pointer(&boxedPointer))
	fmt.Println("any holding *Order:   data word == the pointer itself?", w.data == unsafe.Pointer(order))

	var a, b any = 1, 2
	wa, wb := wordsOf(unsafe.Pointer(&a)), wordsOf(unsafe.Pointer(&b))
	fmt.Println("two anys holding ints: same type word?", wa.typ == wb.typ, " same data word?", wa.data == wb.data)

	verr := &ValidationError{Field: "amount"}
	err = verr
	var asAny any = verr
	we, wn := wordsOf(unsafe.Pointer(&err)), wordsOf(unsafe.Pointer(&asAny))
	fmt.Println("error and any holding the same *ValidationError: same data word?", we.data == wn.data, " same type word?", we.typ == wn.typ, "(an itab for error, a type for any)")

	// == compares both words: the type first, then the values they point at.
	fmt.Println("any(7) == any(7)         ", any(7) == any(7))
	fmt.Println("any(int64(7)) == any(7)  ", any(int64(7)) == any(7))
	fmt.Println("any([]int{1}) == any([]int{1}) panics:", panicOf(func() { _ = any([]int{1}) == any([]int{1}) }))
}
