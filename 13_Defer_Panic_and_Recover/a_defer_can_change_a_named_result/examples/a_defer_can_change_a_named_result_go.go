// A return statement sets the result parameters first and runs the deferred
// calls second, so a deferred closure that names a result can still change
// it: wrap the error, replace it with a recovered panic, or report an error
// from Close that would otherwise be lost. A closure that captured a local
// copy changes nothing the caller sees.
//
//	go build a_defer_can_change_a_named_result_go.go && ./a_defer_can_change_a_named_result_go
package main

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func doubledNamed() (n int) {
	defer func() { n *= 2 }() // n is the result: the caller sees 42
	return 21
}

func doubledUnnamed() int {
	n := 21
	defer func() { n *= 2 }() // n is a local: the result was copied out already
	return n
}

var errDiskFull = errors.New("disk full")

// saveOrder wraps whatever error it returns, on every path, in one place.
func saveOrder(id int, fail bool) (err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("saving order %d: %w", id, err)
		}
	}()
	if fail {
		return errDiskFull
	}
	return nil
}

// mustCents panics on a bad price; totalCents turns that panic into an error.
func mustCents(price string) int {
	n, err := strconv.Atoi(price)
	if err != nil {
		panic(fmt.Sprintf("bad price %q", price))
	}
	return n
}

func totalCents(prices []string) (total int, err error) {
	defer func() {
		if r := recover(); r != nil {
			total, err = 0, fmt.Errorf("totalling prices: %v", r)
		}
	}()
	for _, p := range prices {
		total += mustCents(p)
	}
	return total, nil
}

// writeOrders reports an error from Close through the named result, but only
// when nothing went wrong earlier. The early Close exists only to make the
// deferred Close fail on every machine.
func writeOrders(closeEarly bool) (err error) {
	f, err := os.CreateTemp("", "orders-*.csv")
	if err != nil {
		return err
	}
	defer os.Remove(f.Name())
	defer func() {
		if cerr := f.Close(); err == nil {
			err = cerr
		}
	}()
	if _, werr := f.WriteString("order-18,1999\n"); werr != nil {
		return werr
	}
	if closeEarly {
		return f.Close()
	}
	return nil
}

func main() {
	fmt.Printf("doubledNamed() = %d, doubledUnnamed() = %d\n", doubledNamed(), doubledUnnamed())

	fmt.Println("saveOrder(18, ok):   err =", saveOrder(18, false))
	err := saveOrder(19, true)
	fmt.Printf("saveOrder(19, fail): err = %v, errors.Is(errDiskFull) = %t\n", err, errors.Is(err, errDiskFull))

	for _, prices := range [][]string{{"1999", "450"}, {"1999", "12x"}} {
		total, err := totalCents(prices)
		fmt.Printf("totalCents(%s) = %d, err = %v\n", strings.Join(prices, " "), total, err)
	}

	fmt.Println("writeOrders(normal):      err =", writeOrders(false))
	err = writeOrders(true)
	fmt.Printf("writeOrders(close twice): err != nil = %t, errors.Is(os.ErrClosed) = %t\n", err != nil, errors.Is(err, os.ErrClosed))
}
