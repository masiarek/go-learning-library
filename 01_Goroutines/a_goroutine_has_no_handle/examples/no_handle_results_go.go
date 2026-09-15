// A goroutine has no handle, and whatever its function returns is discarded.
// So each goroutine sends its result -- the value, the error, and which input
// it came from -- and main puts the results back in the order of the inputs.
//
//	go run no_handle_results_go.go
package main

import (
	"fmt"
	"strconv"
)

// parsed is what one goroutine sends back.
type parsed struct {
	line     int
	quantity int
	err      error
}

func main() {
	lines := []string{"12", "7", "seven", "30", ""}

	results := make(chan parsed)
	for i, text := range lines {
		go func() {
			// `go strconv.Atoi(text)` would compile, and throw both results away.
			quantity, err := strconv.Atoi(text)
			results <- parsed{line: i, quantity: quantity, err: err}
		}()
	}

	// Results arrive in the order the goroutines happen to finish.
	// The line number puts each one back where it belongs.
	byLine := make([]parsed, len(lines))
	for range lines {
		r := <-results
		byLine[r.line] = r
	}

	total := 0
	for _, r := range byLine {
		if r.err != nil {
			fmt.Printf("line %d: error: %v\n", r.line+1, r.err)
			continue
		}
		fmt.Printf("line %d: quantity %d\n", r.line+1, r.quantity)
		total += r.quantity
	}
	fmt.Println("total of the lines that parsed:", total)
}
