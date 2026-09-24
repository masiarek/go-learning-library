// A defer statement saves the function value and its arguments the moment it
// runs; only the call itself waits for the surrounding function to return. A
// closure reads its variables when it runs, so the two forms print different
// values. A method's receiver is an argument too.
//
//	go build defer_evaluates_its_arguments_now_go.go && ./defer_evaluates_its_arguments_now_go
package main

import "fmt"

// Tally counts the orders a worker has handled.
type Tally struct{ orders int }

// Report has a value receiver: defer t.Report() copies t at the defer statement.
func (t Tally) Report() { fmt.Println("  Report (value receiver) saw orders =", t.orders) }

// ReportLive has a pointer receiver: the pointer is saved now, the field is read at exit.
func (t *Tally) ReportLive() { fmt.Println("  ReportLive (pointer receiver) saw orders =", t.orders) }

func argumentIsSavedNow() {
	handled := 1
	defer fmt.Println("  defer fmt.Println(handled) printed handled =", handled)
	handled = 2
	fmt.Println("argumentIsSavedNow: handled =", handled, "at exit")
}

func closureReadsAtExit() {
	handled := 1
	defer func() { fmt.Println("  the closure printed handled =", handled) }()
	handled = 2
	fmt.Println("closureReadsAtExit: handled =", handled, "at exit")
}

func receiverIsSavedNow() {
	t := Tally{orders: 1}
	defer t.Report()
	defer t.ReportLive()
	t.orders = 5
	fmt.Println("receiverIsSavedNow: t.orders =", t.orders, "at exit")
}

func functionValueIsSavedNow() {
	report := func() { fmt.Println("  ran the first report") }
	defer report()
	report = func() { fmt.Println("  ran the second report") }
	fmt.Println("functionValueIsSavedNow: report now names the second report")
}

func main() {
	argumentIsSavedNow()
	closureReadsAtExit()
	receiverIsSavedNow()
	functionValueIsSavedNow()
}
