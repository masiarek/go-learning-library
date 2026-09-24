// An interface value is nil only when it holds no type at all. A function
// that declares a *ValidationError variable and returns it puts the type
// *ValidationError into the error it returns even when the pointer is nil --
// so the caller's err != nil is true, %v prints <nil>, and calling Error()
// dereferences a nil pointer. The fix is to return a literal nil.
//
//	go build a_nil_pointer_in_an_interface_is_not_nil_go.go && ./a_nil_pointer_in_an_interface_is_not_nil_go
package main

import (
	"fmt"
	"reflect"
)

type ValidationError struct{ Field string }

func (e *ValidationError) Error() string { return "invalid " + e.Field }

// validateTyped returns its *ValidationError variable on every path. When the
// amount is fine the variable is a nil pointer -- and the error is not nil.
func validateTyped(amount int) error {
	var verr *ValidationError
	if amount < 0 {
		verr = &ValidationError{Field: "amount"}
	}
	return verr
}

// validate returns a literal nil on the good path: no type, no pointer.
func validate(amount int) error {
	if amount < 0 {
		return &ValidationError{Field: "amount"}
	}
	return nil
}

// isNilPointerInside reports an error that is non-nil only because it holds
// a typed nil pointer. reflect.ValueOf(nil) is the zero Value, and IsNil on
// that panics, so the err == nil check comes first.
func isNilPointerInside(err error) bool {
	if err == nil {
		return false
	}
	v := reflect.ValueOf(err)
	return v.Kind() == reflect.Pointer && v.IsNil()
}

func panicOf(f func()) (value any) {
	defer func() { value = recover() }()
	f()
	return "none"
}

func main() {
	err := validateTyped(10)
	fmt.Println("validateTyped(10):")
	fmt.Printf("  %-32s %t\n", "err == nil", err == nil)
	fmt.Printf("  %-32s %T\n", "%T", err)
	fmt.Printf("  %-32s %v\n", "%v", err)
	fmt.Printf("  %-32s %t\n", "err == (*ValidationError)(nil)", err == (*ValidationError)(nil))
	fmt.Printf("  %-32s %v, %t\n", "reflect Kind(), IsNil()", reflect.ValueOf(err).Kind(), reflect.ValueOf(err).IsNil())
	fmt.Printf("  %-32s %v\n", "err.Error() panicked with", panicOf(func() { _ = err.Error() }))

	err = validate(10)
	fmt.Println("validate(10):")
	fmt.Printf("  %-32s %t\n", "err == nil", err == nil)
	fmt.Printf("  %-32s %T\n", "%T", err)
	fmt.Printf("  %-32s %v\n", "%v", err)

	err = validate(-5)
	fmt.Println("validate(-5):")
	fmt.Printf("  %-32s %t\n", "err == nil", err == nil)
	fmt.Printf("  %-32s %T\n", "%T", err)
	fmt.Printf("  %-32s %v\n", "%v", err)

	fmt.Println("the diagnostic, over three results:")
	for _, e := range []error{validateTyped(1), validate(1), validate(-1)} {
		fmt.Printf("  isNilPointerInside %-5t  err == nil %-5t  %T\n", isNilPointerInside(e), e == nil, e)
	}
}
