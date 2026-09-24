// Kata: an HTTP handler turns whatever error came back, however deeply it was
// wrapped, into a status code with errors.As, and falls back to 500.
//
//	go build errors_as_finds_a_type_in_the_chain_kata_go.go && ./errors_as_finds_a_type_in_the_chain_kata_go
package main

import (
	"errors"
	"fmt"
)

type NotFoundError struct{ ID int }

func (e *NotFoundError) Error() string { return fmt.Sprintf("order %d not found", e.ID) }

type QuotaError struct{ Limit int }

func (e QuotaError) Error() string { return fmt.Sprintf("quota of %d exceeded", e.Limit) }

// statusOf maps an error to the HTTP status a handler should answer with.
func statusOf(err error) int {
	var nf *NotFoundError
	var q QuotaError
	switch {
	case err == nil:
		return 200
	case errors.As(err, &nf):
		return 404
	case errors.As(err, &q):
		return 429
	default:
		return 500
	}
}

func main() {
	results := []error{
		nil,
		&NotFoundError{7},
		fmt.Errorf("handle: %w", fmt.Errorf("load: %w", &NotFoundError{8})),
		fmt.Errorf("reserve: %w", QuotaError{10}),
		fmt.Errorf("reserve: %v", QuotaError{10}),
		errors.New("database unreachable"),
	}
	for _, err := range results {
		fmt.Printf("%d  %v\n", statusOf(err), err)
	}
}
