// The same kind of worker, twice, and this time main waits for it: first with
// WaitGroup.Go, new in Go 1.25, then with the Add and Done calls that code
// written before Go 1.25 spells out. Each worker's deferred Flush runs.
//
//	go run main_does_not_wait_waitgroup_go.go
package main

import (
	"bufio"
	"fmt"
	"os"
	"sync"
	"time"
)

// logOrders writes orders to a buffered writer, and its deferred Flush empties it.
func logOrders(worker string, orders ...string) {
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()

	time.Sleep(1 * time.Second) // a second's work before anything is written
	for _, order := range orders {
		fmt.Fprintf(out, "%s: order %s\n", worker, order)
	}
}

func main() {
	// Go 1.25: Go counts the task, starts the goroutine, and marks the task
	// done when the function returns.
	var withGo sync.WaitGroup
	withGo.Go(func() { logOrders("wg.Go   ", "A-1001", "A-1002") })
	withGo.Wait()

	// Before Go 1.25: the same three steps, written out.
	var withAdd sync.WaitGroup
	withAdd.Add(1) // before the go statement, never inside the goroutine
	go func() {
		defer withAdd.Done()
		logOrders("Add/Done", "A-1003", "A-1004")
	}()
	withAdd.Wait()

	fmt.Println("main:     both workers flushed; returning")
}
