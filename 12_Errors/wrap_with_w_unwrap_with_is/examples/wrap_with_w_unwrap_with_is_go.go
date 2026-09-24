// Wrapping with %w keeps the cause and %v drops it: the two errors print the
// same text, but only the wrapped one answers errors.Is. Is walks the chain
// of Unwrap results and finds the sentinel wherever it sits; == compares only
// the outermost value. A type with an Is method decides what it matches.
//
//	go build wrap_with_w_unwrap_with_is_go.go && ./wrap_with_w_unwrap_with_is_go
package main

import (
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"strings"
)

// ErrNotFound is a sentinel: one exported value that callers compare against.
var ErrNotFound = errors.New("order not found")

// findOrder fails for every id, says which id, and keeps the sentinel underneath.
func findOrder(id int) error {
	return fmt.Errorf("find order %d: %w", id, ErrNotFound)
}

// ErrRetryable is what a caller asks about; HTTPError answers through its Is method.
var ErrRetryable = errors.New("retryable")

// HTTPError is a failed call to another service.
type HTTPError struct{ Status int }

func (e HTTPError) Error() string { return fmt.Sprintf("http status %d", e.Status) }

// Is makes every 5xx HTTPError match ErrRetryable without being equal to it.
func (e HTTPError) Is(target error) bool { return target == ErrRetryable && e.Status >= 500 }

func main() {
	wrapped := fmt.Errorf("fulfil order 7: %w", findOrder(7))
	formatted := fmt.Errorf("fulfil order 7: %v", findOrder(7))
	fmt.Println("wrapped   :", wrapped)
	fmt.Println("formatted :", formatted)
	fmt.Println("same text :", wrapped.Error() == formatted.Error())
	fmt.Println()

	fmt.Println("errors.Is(wrapped, ErrNotFound)   =", errors.Is(wrapped, ErrNotFound))
	fmt.Println("errors.Is(formatted, ErrNotFound) =", errors.Is(formatted, ErrNotFound))
	fmt.Println("wrapped == ErrNotFound            =", wrapped == ErrNotFound)
	fmt.Println()

	// Unwrap takes one layer off: fulfil -> find -> the sentinel -> nil.
	fmt.Println("Unwrap(wrapped)         :", errors.Unwrap(wrapped))
	fmt.Println("Unwrap(Unwrap(wrapped)) :", errors.Unwrap(errors.Unwrap(wrapped)))
	fmt.Println("  ... == ErrNotFound    :", errors.Unwrap(errors.Unwrap(wrapped)) == ErrNotFound)
	fmt.Println("Unwrap(ErrNotFound)     :", errors.Unwrap(ErrNotFound))
	fmt.Println("Unwrap(formatted)       :", errors.Unwrap(formatted))
	fmt.Println()

	// Two sentinels from the standard library, wrapped by whoever returned them.
	_, err := io.ReadFull(strings.NewReader(""), make([]byte, 4))
	err = fmt.Errorf("read order header: %w", err)
	fmt.Println("errors.Is(err, io.EOF)             =", errors.Is(err, io.EOF), "-", err)
	_, err = os.Open("orders/does-not-exist.csv")
	fmt.Println("os.Open: err == fs.ErrNotExist     =", err == fs.ErrNotExist)
	fmt.Println("os.Open: errors.Is(fs.ErrNotExist) =", errors.Is(err, fs.ErrNotExist))
	fmt.Println()

	gateway := fmt.Errorf("call pricing service: %w", HTTPError{503})
	missing := fmt.Errorf("call pricing service: %w", HTTPError{404})
	fmt.Println("503: errors.Is(err, ErrRetryable)   =", errors.Is(gateway, ErrRetryable))
	fmt.Println("404: errors.Is(err, ErrRetryable)   =", errors.Is(missing, ErrRetryable))
	fmt.Println("503: errors.Is(err, HTTPError{503}) =", errors.Is(gateway, HTTPError{503}))
}
