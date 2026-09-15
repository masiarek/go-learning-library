// A deadline is a cancel with a clock: WithTimeout and WithDeadline close
// Done when the time comes, and Err then says context.DeadlineExceeded.
// A child context can shorten its parent's deadline, never extend it.
//
//	go build a_deadline_is_a_cancel_with_a_clock_go.go && ./a_deadline_is_a_cancel_with_a_clock_go
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// lookupPrice stands in for a call to a slow supplier: the answer takes three
// seconds, and the lookup gives up as soon as ctx is done.
func lookupPrice(ctx context.Context) (int, error) {
	select {
	case <-time.After(3 * time.Second):
		return 1299, nil
	case <-ctx.Done():
		return 0, ctx.Err()
	}
}

func main() {
	bg := context.Background()

	fmt.Println("1. a 100ms timeout on a lookup that takes 3s")
	start := time.Now()
	ctx, cancel := context.WithTimeout(bg, 100*time.Millisecond)
	defer cancel()
	price, err := lookupPrice(ctx)
	elapsed := time.Since(start)
	fmt.Println("   price, err:", price, err)
	fmt.Println("   errors.Is(err, context.DeadlineExceeded):", errors.Is(err, context.DeadlineExceeded))
	fmt.Println("   errors.Is(err, context.Canceled):        ", errors.Is(err, context.Canceled))
	fmt.Println("   waited at least 100ms:", elapsed >= 100*time.Millisecond)
	fmt.Println("   gave up before 3s:    ", elapsed < 3*time.Second)

	fmt.Println("2. the same timeout, with cancel() called before the clock runs out")
	ctx, cancel = context.WithTimeout(bg, 100*time.Millisecond)
	cancel()
	_, err = lookupPrice(ctx)
	fmt.Println("   err:", err)

	fmt.Println("3. a deadline that has already passed")
	ctx, cancel = context.WithDeadline(bg, time.Now().Add(-time.Second))
	defer cancel()
	fmt.Println("   ctx.Err() at once:", ctx.Err())

	fmt.Println("4. children of a parent whose deadline is a minute away")
	parent, cancelParent := context.WithTimeout(bg, time.Minute)
	defer cancelParent()
	longer, cancelLonger := context.WithTimeout(parent, time.Hour)
	defer cancelLonger()
	shorter, cancelShorter := context.WithTimeout(parent, time.Second)
	defer cancelShorter()
	pd, _ := parent.Deadline()
	ld, _ := longer.Deadline()
	sd, _ := shorter.Deadline()
	fmt.Println("   asked for 1h, deadline equals the parent's:", ld.Equal(pd))
	fmt.Println("   asked for 1s, deadline before the parent's:", sd.Before(pd))

	fmt.Println("5. a parent's 100ms deadline passes under a child that asked for 1h")
	parent, cancelParent = context.WithTimeout(bg, 100*time.Millisecond)
	defer cancelParent()
	child, cancelChild := context.WithTimeout(parent, time.Hour)
	defer cancelChild()
	<-child.Done()
	fmt.Println("   child.Err():", child.Err())
}
