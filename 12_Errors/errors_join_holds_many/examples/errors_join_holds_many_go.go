// errors.Join holds several errors in one: Error() joins their texts with
// newlines, errors.Is and errors.As search all of them, and a Join of nothing
// but nils is nil. fmt.Errorf with two %w verbs wraps both operands the same
// way. Either kind has Unwrap() []error, which errors.Unwrap does not call.
//
//	go build errors_join_holds_many_go.go && ./errors_join_holds_many_go
package main

import (
	"errors"
	"fmt"
)

var (
	ErrNoCustomer  = errors.New("customer is empty")
	ErrBadQuantity = errors.New("quantity must be positive")
)

// UnknownSKUError names the sku the catalogue does not have.
type UnknownSKUError struct{ SKU string }

func (e UnknownSKUError) Error() string { return "unknown sku " + e.SKU }

type Order struct {
	Customer string
	SKU      string
	Quantity int
}

var catalogue = map[string]bool{"lamp": true, "desk": true}

// validate reports every problem with an order, not only the first one found.
func validate(o Order) error {
	var problems []error
	if o.Customer == "" {
		problems = append(problems, ErrNoCustomer)
	}
	if !catalogue[o.SKU] {
		problems = append(problems, UnknownSKUError{o.SKU})
	}
	if o.Quantity <= 0 {
		problems = append(problems, fmt.Errorf("quantity %d: %w", o.Quantity, ErrBadQuantity))
	}
	return errors.Join(problems...)
}

func main() {
	err := validate(Order{Customer: "", SKU: "chair", Quantity: 0})
	fmt.Printf("Error() of the joined error:\n%v\n", err)
	fmt.Printf("as one quoted string: %q\n", err.Error())
	fmt.Println()

	fmt.Println("errors.Is(err, ErrNoCustomer)  =", errors.Is(err, ErrNoCustomer))
	fmt.Println("errors.Is(err, ErrBadQuantity) =", errors.Is(err, ErrBadQuantity))
	var unknown UnknownSKUError
	fmt.Println("errors.As(err, &unknown)       =", errors.As(err, &unknown), "-> SKU:", unknown.SKU)
	fmt.Println("errors.Unwrap(err) == nil      =", errors.Unwrap(err) == nil)
	if multi, ok := err.(interface{ Unwrap() []error }); ok {
		fmt.Printf("Unwrap() []error holds         %d errors\n", len(multi.Unwrap()))
	}
	fmt.Println()

	fmt.Println("a valid order         :", validate(Order{"ada", "lamp", 2}))
	fmt.Println("errors.Join() == nil  :", errors.Join() == nil)
	fmt.Println("Join(nil, nil) == nil :", errors.Join(nil, nil) == nil)
	fmt.Println()

	// fmt.Errorf with two %w verbs wraps both; with one it is the old single chain.
	both := fmt.Errorf("order 12: %w; %w", ErrNoCustomer, ErrBadQuantity)
	fmt.Println("two %w   :", both)
	fmt.Println("errors.Is(both, ErrNoCustomer), errors.Is(both, ErrBadQuantity) =", errors.Is(both, ErrNoCustomer), errors.Is(both, ErrBadQuantity))
	fmt.Println("errors.Unwrap(both) == nil =", errors.Unwrap(both) == nil)
	one := fmt.Errorf("order 13: %w", ErrNoCustomer)
	fmt.Println("one %w   :", one)
	fmt.Println("errors.Unwrap(one)         =", errors.Unwrap(one))
}
