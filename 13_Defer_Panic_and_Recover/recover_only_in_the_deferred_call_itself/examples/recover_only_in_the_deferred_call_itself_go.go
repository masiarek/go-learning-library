// recover stops a panic only when the deferred function itself calls it. A
// helper that the deferred function calls gets nil; so does `defer recover()`
// (there recover is the deferred function, not called by one); so does a
// recover outside any panic. Since Go 1.21 a panic(nil) recovers as a
// *runtime.PanicNilError, so during a panic the recovered value is never nil;
// a runtime error recovers as a value that implements runtime.Error.
//
//	go build recover_only_in_the_deferred_call_itself_go.go && ./recover_only_in_the_deferred_call_itself_go
package main

import (
	"errors"
	"fmt"
	"runtime"
)

// caught runs job and returns what its own deferred closure recovered, or
// "no panic" if the job returned normally.
func caught(job func()) (value any) {
	defer func() {
		if r := recover(); r != nil {
			value = r
		}
	}()
	job()
	return "no panic"
}

func recoverInTheDeferredFunction() {
	fmt.Println("   the deferred function recovered:", recover())
}

func recoverInAHelper() {
	fmt.Println("   a helper called by the deferred function got:", helperRecover())
}

func helperRecover() any { return recover() }

func main() {
	fmt.Println("1. recover outside any panic:", recover())

	fmt.Println("2. defer recoverInTheDeferredFunction():")
	fmt.Println("   the caller saw:", caught(func() {
		defer recoverInTheDeferredFunction()
		panic("invoice 18 has no customer")
	}))

	fmt.Println("3. defer recoverInAHelper():")
	fmt.Println("   the caller saw:", caught(func() {
		defer recoverInAHelper()
		panic("invoice 19 has no customer")
	}))

	fmt.Println("4. defer recover():")
	fmt.Println("   the caller saw:", caught(func() {
		defer recover()
		panic("invoice 20 has no customer")
	}))

	fmt.Println("5. panic(nil):")
	v := caught(func() { panic(nil) })
	fmt.Printf("   %T: %v\n", v, v)

	fmt.Println("6. a runtime error:")
	v = caught(func() {
		prices := []int{1999, 450, 1200}
		i := 3
		fmt.Println(prices[i])
	})
	err, isError := v.(error)
	var re runtime.Error
	fmt.Printf("   %v\n   is an error: %t, errors.As runtime.Error: %t\n", v, isError, errors.As(err, &re))
}
