// Kata: retry keeps the last failure. RetryError records the attempts and
// wraps the last error through Unwrap, so a caller can ask errors.Is for the
// sentinel and errors.As for the count.
//
//	go build an_error_type_with_unwrap_kata_go.go && ./an_error_type_with_unwrap_kata_go
package main

import (
	"errors"
	"fmt"
)

var ErrUnavailable = errors.New("service unavailable")

// RetryError says how many attempts were made and keeps the last error.
type RetryError struct {
	Attempts int
	Last     error
}

func (e *RetryError) Error() string {
	return fmt.Sprintf("gave up after %d attempts: %v", e.Attempts, e.Last)
}
func (e *RetryError) Unwrap() error { return e.Last }

// retry calls op up to n times and wraps the last failure.
func retry(n int, op func(attempt int) error) error {
	var last error
	for attempt := 1; attempt <= n; attempt++ {
		last = op(attempt)
		if last == nil {
			return nil
		}
	}
	return &RetryError{n, last}
}

func main() {
	err := retry(3, func(attempt int) error {
		return fmt.Errorf("attempt %d: %w", attempt, ErrUnavailable)
	})
	fmt.Println("err:", err)
	fmt.Println("errors.Is(err, ErrUnavailable) =", errors.Is(err, ErrUnavailable))
	var re *RetryError
	if errors.As(err, &re) {
		fmt.Println("attempts:", re.Attempts)
	}
	fmt.Println("succeeds on the second try:", retry(3, func(attempt int) error {
		if attempt < 2 {
			return ErrUnavailable
		}
		return nil
	}))
}
