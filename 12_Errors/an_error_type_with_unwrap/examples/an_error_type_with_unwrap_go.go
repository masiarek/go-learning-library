// An error type wraps by giving itself an Unwrap method: Unwrap() error for
// one cause, Unwrap() []error for several. errors.Is and errors.As see
// through either. Wrapping keeps the cause in the chain; %v turns it into
// text, which is right when the cause is a detail callers should not rely on.
//
//	go build an_error_type_with_unwrap_go.go && ./an_error_type_with_unwrap_go
package main

import (
	"errors"
	"fmt"
	"strconv"
)

var ErrTimeout = errors.New("timeout")

// QueryError adds which query failed and keeps the cause.
type QueryError struct {
	Query string
	Err   error
}

func (e *QueryError) Error() string { return "query " + strconv.Quote(e.Query) + ": " + e.Err.Error() }
func (e *QueryError) Unwrap() error { return e.Err }

// BatchError holds one error per failed statement of a batch.
type BatchError struct{ Errs []error }

func (e *BatchError) Error() string   { return fmt.Sprintf("%d statements failed", len(e.Errs)) }
func (e *BatchError) Unwrap() []error { return e.Errs }

func runQuery(query string) error {
	if query == "select price from quotes" {
		return &QueryError{query, ErrTimeout}
	}
	return nil
}

func runBatch(queries ...string) error {
	var failed []error
	for _, q := range queries {
		if err := runQuery(q); err != nil {
			failed = append(failed, err)
		}
	}
	if len(failed) == 0 {
		return nil
	}
	return &BatchError{failed}
}

// ErrConfigInvalid is all a caller of loadConfig may test for. The parser
// behind it is a detail, so its error is folded in as text with %v.
var ErrConfigInvalid = errors.New("config invalid")

func loadConfig(workers string) (int, error) {
	n, err := strconv.Atoi(workers)
	if err != nil {
		return 0, fmt.Errorf("%w: workers: %v", ErrConfigInvalid, err)
	}
	return n, nil
}

func main() {
	err := fmt.Errorf("refresh prices: %w", runQuery("select price from quotes"))
	fmt.Println("err:", err)
	fmt.Println("errors.Is(err, ErrTimeout) =", errors.Is(err, ErrTimeout))
	var qe *QueryError
	fmt.Println("errors.As(err, &qe)        =", errors.As(err, &qe), "-> Query:", qe.Query)
	fmt.Println()

	batch := runBatch("select 1", "select price from quotes", "select price from quotes")
	fmt.Println("batch:", batch)
	fmt.Println("errors.Is(batch, ErrTimeout) =", errors.Is(batch, ErrTimeout))
	fmt.Println("errors.Unwrap(batch) == nil  =", errors.Unwrap(batch) == nil, "(Unwrap() []error is not Unwrap() error)")
	fmt.Println()

	_, err = loadConfig("ten")
	fmt.Println("loadConfig:", err)
	fmt.Println("errors.Is(err, ErrConfigInvalid)  =", errors.Is(err, ErrConfigInvalid))
	fmt.Println("errors.Is(err, strconv.ErrSyntax) =", errors.Is(err, strconv.ErrSyntax), "(the parser's error is text)")
	_, atoiErr := strconv.Atoi("ten")
	leaky := fmt.Errorf("%w: workers: %w", ErrConfigInvalid, atoiErr)
	fmt.Println("had it been %w instead            =", errors.Is(leaky, strconv.ErrSyntax), "(now callers can depend on strconv)")
	fmt.Println()

	// The chain reads left to right, so each message is lower case and ends without punctuation.
	fmt.Println("bad :", fmt.Errorf("start server: %w", errors.New("Config could not be loaded.")))
	fmt.Println("good:", fmt.Errorf("start server: %w", errors.New("config could not be loaded")))
}
