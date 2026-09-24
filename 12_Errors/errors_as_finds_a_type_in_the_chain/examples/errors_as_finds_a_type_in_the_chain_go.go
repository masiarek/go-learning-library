// errors.As finds the first error in the chain whose concrete type can be
// assigned to the target, through any number of wrapping layers. The target
// is a non-nil pointer to a type that implements error, or to an interface;
// whether the type's methods are on the pointer or the value decides which
// target works. A wrong target panics, and the four messages are below.
//
//	go build errors_as_finds_a_type_in_the_chain_go.go && ./errors_as_finds_a_type_in_the_chain_go
package main

import (
	"errors"
	"fmt"
)

// NotFoundError says what was looked up. Its methods are on the pointer, so
// the value travelling inside an error is a *NotFoundError.
type NotFoundError struct {
	Kind string
	ID   int
}

func (e *NotFoundError) Error() string   { return fmt.Sprintf("%s %d not found", e.Kind, e.ID) }
func (e *NotFoundError) HTTPStatus() int { return 404 }

// QuotaError's method is on the value, so a QuotaError travels as a value.
type QuotaError struct{ Limit int }

func (e QuotaError) Error() string { return fmt.Sprintf("quota of %d exceeded", e.Limit) }

func findOrder(id int) error { return &NotFoundError{"order", id} }
func loadOrder(id int) error { return fmt.Errorf("load order: %w", findOrder(id)) }
func handle(id int) error    { return fmt.Errorf("handle request: %w", loadOrder(id)) }
func reserve(n int) error    { return fmt.Errorf("reserve %d: %w", n, QuotaError{10}) }

func main() {
	err := handle(42)
	fmt.Println("err:", err)
	var nf *NotFoundError
	fmt.Println("errors.As(err, &nf)  =", errors.As(err, &nf), "-> Kind:", nf.Kind, "ID:", nf.ID)
	_, direct := err.(*NotFoundError)
	fmt.Println("err.(*NotFoundError) =", direct, "(a type assertion sees only the outer layer)")
	var status interface{ HTTPStatus() int }
	fmt.Println("interface target     =", errors.As(err, &status), "-> status", status.HTTPStatus())
	fmt.Println()

	qerr := reserve(11)
	var q QuotaError
	var qp *QuotaError
	fmt.Println("value stored, value target:   errors.As(qerr, &q)  =", errors.As(qerr, &q), "-> Limit:", q.Limit)
	fmt.Println("value stored, pointer target: errors.As(qerr, &qp) =", errors.As(qerr, &qp))
	fmt.Println()

	// Each wrong target goes in as an `any`, so that go vet's errorsas check,
	// which reads the static type, cannot refuse the call before it runs.
	var nilTarget *NotFoundError
	var value NotFoundError
	wrong := []struct {
		call   string
		target any
	}{
		{"errors.As(err, nil)", nil},
		{"errors.As(err, NotFoundError{})", NotFoundError{}},
		{"errors.As(err, nilTarget)", nilTarget},
		{"errors.As(err, &value)", &value},
	}
	for _, w := range wrong {
		fmt.Printf("%-32s panics: %v\n", w.call, panicOf(func() { errors.As(err, w.target) }))
	}
}

// panicOf runs f and returns what it panicked with, or "nothing".
func panicOf(f func()) (value any) {
	defer func() {
		if r := recover(); r != nil {
			value = r
		}
	}()
	f()
	return "nothing"
}
