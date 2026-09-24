// Kata: pick lines. parsePick wraps strconv's error when the quantity is not
// a number and ErrBadQuantity when it is not positive; the caller sorts the
// failures with errors.Is and peels one chain apart with errors.Unwrap.
//
//	go build wrap_with_w_unwrap_with_is_kata_go.go && ./wrap_with_w_unwrap_with_is_kata_go
package main

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
)

var ErrBadQuantity = errors.New("quantity must be positive")

// parsePick reads "sku quantity" and returns the quantity.
func parsePick(line int, text string) (int, error) {
	fields := strings.Fields(text)
	if len(fields) != 2 {
		return 0, fmt.Errorf("line %d: want sku and quantity, got %q", line, text)
	}
	n, err := strconv.Atoi(fields[1])
	if err != nil {
		return 0, fmt.Errorf("line %d: %w", line, err)
	}
	if n <= 0 {
		return 0, fmt.Errorf("line %d: quantity %d: %w", line, n, ErrBadQuantity)
	}
	return n, nil
}

func main() {
	lines := []string{"lamp 4", "desk x", "chair -1", "shelf"}
	var chain error
	for i, text := range lines {
		n, err := parsePick(i+1, text)
		switch {
		case err == nil:
			fmt.Printf("line %d: pick %d\n", i+1, n)
		case errors.Is(err, ErrBadQuantity):
			fmt.Printf("line %d: bad quantity\n", i+1)
		case errors.Is(err, strconv.ErrSyntax):
			fmt.Printf("line %d: not a number\n", i+1)
			chain = err
		default:
			fmt.Printf("line %d: other: %v\n", i+1, err)
		}
	}
	fmt.Println("the chain behind line 2, one Unwrap at a time:")
	for layer := chain; layer != nil; layer = errors.Unwrap(layer) {
		fmt.Printf("  %T: %v\n", layer, layer)
	}
}
