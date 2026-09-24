// Kata: validate a whole batch. Each order's problems are joined, each failed
// order is wrapped with its position, and the batch error joins those. The
// caller counts failed orders through Unwrap() []error and asks errors.Is
// whether any order anywhere in the tree had no customer.
//
//	go build errors_join_holds_many_kata_go.go && ./errors_join_holds_many_kata_go
package main

import (
	"errors"
	"fmt"
)

var (
	ErrNoCustomer  = errors.New("customer is empty")
	ErrBadQuantity = errors.New("quantity must be positive")
)

type Order struct {
	Customer string
	Quantity int
}

func validate(o Order) error {
	var problems []error
	if o.Customer == "" {
		problems = append(problems, ErrNoCustomer)
	}
	if o.Quantity <= 0 {
		problems = append(problems, fmt.Errorf("quantity %d: %w", o.Quantity, ErrBadQuantity))
	}
	return errors.Join(problems...)
}

func validateBatch(orders []Order) error {
	var failed []error
	for i, o := range orders {
		if err := validate(o); err != nil {
			failed = append(failed, fmt.Errorf("order %d: %w", i+1, err))
		}
	}
	return errors.Join(failed...)
}

func main() {
	batch := []Order{{"ada", 2}, {"", 0}, {"grace", -1}, {"linus", 5}}
	err := validateBatch(batch)
	fmt.Println(err)
	fmt.Println()
	if multi, ok := err.(interface{ Unwrap() []error }); ok {
		fmt.Println("failed orders:", len(multi.Unwrap()), "of", len(batch))
	}
	fmt.Println("some order had no customer:", errors.Is(err, ErrNoCustomer))
	fmt.Println("all valid batch:", validateBatch([]Order{{"ada", 1}}))
}
