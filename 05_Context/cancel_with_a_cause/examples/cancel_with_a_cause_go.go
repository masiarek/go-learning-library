// ctx.Err() says only that a context was canceled, or that its deadline
// passed. WithCancelCause records why, and context.Cause reads the reason
// back, from that context or from any context derived from it.
//
//	go build cancel_with_a_cause_go.go && ./cancel_with_a_cause_go
package main

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

var (
	errOutOfStock   = errors.New("warehouse: out of stock")
	errSupplierSlow = errors.New("supplier: no quote within 100ms")
)

// waitForCancel is a step with nothing to do until it is told to stop.
func waitForCancel(ctx context.Context) error {
	<-ctx.Done()
	return ctx.Err()
}

func main() {
	bg := context.Background()

	fmt.Println("1. three steps of one order; the stock check fails and cancels the rest")
	order, cancelOrder := context.WithCancelCause(bg)
	defer cancelOrder(nil)
	label, cancelLabel := context.WithCancel(order) // made before anything fails
	defer cancelLabel()

	steps := []struct {
		name string
		run  func(context.Context) error
	}{
		{"stock", func(context.Context) error { return errOutOfStock }},
		{"payment", waitForCancel},
		{"shipping", waitForCancel},
	}
	returned := make([]error, len(steps))
	var wg sync.WaitGroup
	for i, s := range steps {
		wg.Go(func() {
			err := s.run(order)
			returned[i] = err
			cancelOrder(err) // every step reports its error; only the first one sticks
		})
	}
	wg.Wait()
	for i, s := range steps {
		fmt.Printf("   %-8s returned:  %v\n", s.name, returned[i])
	}
	fmt.Println("   order.Err():         ", order.Err())
	fmt.Println("   context.Cause(order):", context.Cause(order))

	fmt.Println("2. Cause through a child, and Cause with no cause given")
	fmt.Println("   label.Err():         ", label.Err())
	fmt.Println("   context.Cause(label):", context.Cause(label))
	fmt.Println("   errors.Is(context.Cause(label), errOutOfStock):", errors.Is(context.Cause(label), errOutOfStock))
	plain, cancelPlain := context.WithCancel(bg)
	fmt.Println("   not canceled yet:        Cause =", context.Cause(plain))
	cancelPlain()
	fmt.Println("   plain WithCancel:        Cause =", context.Cause(plain))
	withNil, cancelWithNil := context.WithCancelCause(bg)
	cancelWithNil(nil)
	fmt.Println("   WithCancelCause, nil:    Cause =", context.Cause(withNil))

	fmt.Println("3. WithTimeoutCause: the cause is recorded only if the clock runs out")
	ctx, cancel := context.WithTimeoutCause(bg, 100*time.Millisecond, errSupplierSlow)
	<-ctx.Done()
	fmt.Printf("   %-21s Err = %-26v Cause = %v\n", "the clock ran out:", ctx.Err(), context.Cause(ctx))
	cancel()
	ctx, cancel = context.WithTimeoutCause(bg, 100*time.Millisecond, errSupplierSlow)
	cancel()
	fmt.Printf("   %-21s Err = %-26v Cause = %v\n", "cancel() came first:", ctx.Err(), context.Cause(ctx))
}
