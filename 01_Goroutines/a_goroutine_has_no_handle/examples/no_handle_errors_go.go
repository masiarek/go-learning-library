// When the work has no value to hand back, only success or failure, the
// channel carries the error alone, nil for success. main receives exactly as
// many errors as it started goroutines, and joins the ones that are not nil.
//
//	go run no_handle_errors_go.go
package main

import (
	"errors"
	"fmt"
	"slices"
	"strings"
)

type order struct {
	sku      string
	quantity int
}

// stock is only read, never written, so every goroutine may look at it.
var stock = map[string]int{"A-1001": 5, "A-1002": 0, "A-1003": 2}

func reserve(o order) error {
	have, ok := stock[o.sku]
	switch {
	case !ok:
		return fmt.Errorf("%s: no such item", o.sku)
	case have < o.quantity:
		return fmt.Errorf("%s: %d wanted, %d in stock", o.sku, o.quantity, have)
	}
	return nil
}

func main() {
	orders := []order{{"A-1001", 3}, {"A-1002", 1}, {"A-1009", 1}, {"A-1003", 2}}

	errs := make(chan error)
	for _, o := range orders {
		go func() { errs <- reserve(o) }()
	}

	var failures []error
	for range orders {
		if err := <-errs; err != nil {
			failures = append(failures, err)
		}
	}

	// Failures arrive in the order the goroutines finished; sort them so the
	// report is the same on every run.
	slices.SortFunc(failures, func(a, b error) int {
		return strings.Compare(a.Error(), b.Error())
	})
	fmt.Printf("%d of %d orders reserved\n", len(orders)-len(failures), len(orders))
	fmt.Println(errors.Join(failures...))
}
