// A defer inside a loop does not run at the end of the iteration; it runs
// when the function returns. A loop that opens a file per iteration and
// defers its Close holds every file open until the loop's function returns.
// The fix is a function per iteration -- a helper or a function literal --
// whose own return runs the Close. The tracker counts opens and closes.
//
//	go build defer_in_a_loop_runs_at_function_end_go.go && ./defer_in_a_loop_runs_at_function_end_go
package main

import (
	"fmt"
	"os"
)

// tracker counts the files a loop opened and closed, and the most open at once.
type tracker struct{ opened, closed, openNow, mostOpen int }

func (t *tracker) open(path string) (*os.File, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	t.opened++
	t.openNow++
	t.mostOpen = max(t.mostOpen, t.openNow)
	return f, nil
}

func (t *tracker) close(f *os.File) {
	f.Close()
	t.closed++
	t.openNow--
}

// deferInTheLoop: every Close waits for this function to return.
func deferInTheLoop(path string, n int, t *tracker) error {
	for range n {
		f, err := t.open(path)
		if err != nil {
			return err
		}
		defer t.close(f)
	}
	fmt.Printf("  end of the loop, still inside the function: closed %d of %d\n", t.closed, t.opened)
	return nil
}

// aHelperPerIteration: readOne's return runs its Close, once per iteration.
func aHelperPerIteration(path string, n int, t *tracker) error {
	for range n {
		if err := readOne(path, t); err != nil {
			return err
		}
	}
	fmt.Printf("  end of the loop, still inside the function: closed %d of %d\n", t.closed, t.opened)
	return nil
}

func readOne(path string, t *tracker) error {
	f, err := t.open(path)
	if err != nil {
		return err
	}
	defer t.close(f)
	return nil
}

// aLiteralPerIteration: the same, with the helper written in place.
func aLiteralPerIteration(path string, n int, t *tracker) error {
	for range n {
		err := func() error {
			f, err := t.open(path)
			if err != nil {
				return err
			}
			defer t.close(f)
			return nil
		}()
		if err != nil {
			return err
		}
	}
	fmt.Printf("  end of the loop, still inside the function: closed %d of %d\n", t.closed, t.opened)
	return nil
}

func main() {
	orders, err := os.CreateTemp("", "orders-*.csv")
	if err != nil {
		panic(err)
	}
	orders.Close()
	defer os.Remove(orders.Name())

	const n = 1000
	loops := []struct {
		name string
		run  func(string, int, *tracker) error
	}{
		{"defer in the loop", deferInTheLoop},
		{"a helper per iteration", aHelperPerIteration},
		{"a function literal per iteration", aLiteralPerIteration},
	}
	for _, loop := range loops {
		fmt.Printf("%s, %d opens:\n", loop.name, n)
		var t tracker
		if err := loop.run(orders.Name(), n, &t); err != nil {
			panic(err)
		}
		fmt.Printf("  after the function returned: closed %d of %d, most open at once: %d\n", t.closed, t.opened, t.mostOpen)
	}
}
