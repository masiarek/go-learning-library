// One cancel() reaches every goroutine that holds the context, or a context
// derived from it, and each of them returns. Cancelling a child never reaches
// its parent.
//
//	go build cancel_reaches_every_goroutine_go.go && ./cancel_reaches_every_goroutine_go
package main

import (
	"context"
	"errors"
	"fmt"
	"sync"
)

// One goroutine per step of an order, each holding its own context:
//
//	order
//	├── payment
//	└── shipping
//	    └── label
type step struct {
	name     string
	ctx      context.Context
	returned chan struct{} // closed when the step's goroutine returns
}

func main() {
	order, cancelOrder := context.WithCancel(context.Background())
	defer cancelOrder()
	payment, cancelPayment := context.WithCancel(order)
	defer cancelPayment()
	shipping, cancelShipping := context.WithCancel(order)
	defer cancelShipping()
	label, cancelLabel := context.WithCancel(shipping)
	defer cancelLabel()

	steps := []*step{
		{name: "order", ctx: order},
		{name: "payment", ctx: payment},
		{name: "shipping", ctx: shipping},
		{name: "label", ctx: label},
	}

	var wg sync.WaitGroup
	for _, s := range steps {
		s.returned = make(chan struct{})
		wg.Go(func() {
			defer close(s.returned)
			<-s.ctx.Done() // real work would select on this alongside its own channels
		})
	}

	report("before any cancel", steps)

	cancelShipping()
	<-steps[2].returned
	<-steps[3].returned
	report("after cancelShipping()", steps)

	cancelOrder()
	wg.Wait()
	report("after cancelOrder()", steps)

	fmt.Println("errors.Is(payment.Err(), context.Canceled):", errors.Is(payment.Err(), context.Canceled))
}

// report prints each step's ctx.Err() and whether its goroutine has returned.
// A goroutine whose context is not canceled cannot have returned, so
// "waiting" is as certain as "returned".
func report(title string, steps []*step) {
	fmt.Println(title + ":")
	for _, s := range steps {
		state := "waiting"
		select {
		case <-s.returned:
			state = "returned"
		default:
		}
		fmt.Printf("  %-9s ctx.Err() = %-17v goroutine %s\n", s.name, s.ctx.Err(), state)
	}
}
