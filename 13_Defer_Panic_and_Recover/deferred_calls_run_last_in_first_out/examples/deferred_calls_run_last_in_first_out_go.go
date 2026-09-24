// Deferred calls run when the surrounding function returns, in the reverse of
// the order they were deferred: the last resource taken is the first released.
// They also run while a panic unwinds the function, and when runtime.Goexit
// ends the goroutine. os.Exit runs none of them; the driver on the page shows
// that, because os.Exit ends the program.
//
//	go build deferred_calls_run_last_in_first_out_go.go && ./deferred_calls_run_last_in_first_out_go
package main

import (
	"fmt"
	"runtime"
	"sync"
)

func postInvoice() {
	fmt.Println("postInvoice: lock the ledger")
	defer fmt.Println("postInvoice: unlock the ledger")
	fmt.Println("postInvoice: open the invoice file")
	defer fmt.Println("postInvoice: close the invoice file")
	fmt.Println("postInvoice: begin the transaction")
	defer fmt.Println("postInvoice: end the transaction")
	fmt.Println("postInvoice: returning")
}

func postInvoiceThatPanics() {
	defer fmt.Println("panicking: unlock the ledger")
	defer fmt.Println("panicking: close the invoice file")
	panic("invoice 18 has no customer")
}

func main() {
	postInvoice()

	fmt.Println()
	func() {
		defer func() { fmt.Println("caller: recovered:", recover()) }()
		postInvoiceThatPanics()
	}()

	fmt.Println()
	var wg sync.WaitGroup
	wg.Go(func() {
		defer fmt.Println("worker: deferred call ran after Goexit")
		runtime.Goexit()
	})
	wg.Wait()
	fmt.Println("main: the worker ended; main goes on")
}
