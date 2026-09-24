// Kata: a `safely` wrapper that turns a panic in a job into an error, in the
// deferred function itself, and tells a runtime error (a bug) from an error
// value the job panicked with, and from anything else.
package main

import (
	"errors"
	"fmt"
	"runtime"
)

var errNoCustomer = errors.New("no customer on the order")

func safely(name string, job func()) (err error) {
	defer func() {
		switch v := recover().(type) {
		case nil:
			// the job returned normally
		case runtime.Error:
			err = fmt.Errorf("%s: bug: %w", name, v)
		case error:
			err = fmt.Errorf("%s: %w", name, v)
		default:
			err = fmt.Errorf("%s: panic: %v", name, v)
		}
	}()
	job()
	return nil
}

func main() {
	jobs := []struct {
		name string
		job  func()
	}{
		{"ship", func() { fmt.Println("   shipped order 18") }},
		{"index", func() { var lines []string; fmt.Println(lines[2]) }},
		{"charge", func() { panic(errNoCustomer) }},
		{"print", func() { panic("printer offline") }},
	}
	for _, j := range jobs {
		err := safely(j.name, j.job)
		var re runtime.Error
		fmt.Printf("%-7s err = %v | runtime.Error: %t | errNoCustomer: %t\n",
			j.name+":", err, errors.As(err, &re), errors.Is(err, errNoCustomer))
	}
}
