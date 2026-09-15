// The first error cancels the rest: what golang.org/x/sync/errgroup does with
// WithContext, built from context.WithCancelCause and a sync.WaitGroup. Three
// tasks fetch the parts of a product page. The reviews service fails at once;
// the price and stock tasks stand in for slow calls, and return only when their
// context is canceled. The first error cancels that context, with itself as the
// cause, and it is the error Wait returns.
//
//	go build first_error_cancels_the_rest_go.go && ./first_error_cancels_the_rest_go
package main

import (
	"context"
	"errors"
	"fmt"
	"sync"
)

// group is errgroup.Group, as returned by errgroup.WithContext, cut down to
// Go and Wait.
type group struct {
	wg      sync.WaitGroup
	cancel  context.CancelCauseFunc
	errOnce sync.Once
	err     error
}

func withContext(parent context.Context) (*group, context.Context) {
	ctx, cancel := context.WithCancelCause(parent)
	return &group{cancel: cancel}, ctx
}

// Go runs task in a new goroutine. The first task to return an error records
// it and cancels the group's context, with that error as the cause.
func (g *group) Go(task func() error) {
	g.wg.Go(func() {
		if err := task(); err != nil {
			g.errOnce.Do(func() {
				g.err = err
				g.cancel(err)
			})
		}
	})
}

// Wait waits for every task, then returns the first error, or nil. Like
// errgroup's Wait, it also cancels the context, so nothing started from it
// outlives the group.
func (g *group) Wait() error {
	g.wg.Wait()
	g.cancel(g.err)
	return g.err
}

func main() {
	fmt.Println("1. price and stock wait on ctx; reviews fails at once")
	g, ctx := withContext(context.Background())
	names := []string{"price", "stock", "reviews"}
	returned := make([]error, len(names)) // each task writes only its own slot

	for i, name := range names[:2] {
		g.Go(func() error {
			<-ctx.Done() // a slow call that gives up when ctx is canceled
			returned[i] = fmt.Errorf("%s: gave up: %w", name, context.Cause(ctx))
			return returned[i]
		})
	}
	g.Go(func() error {
		returned[2] = errors.New("reviews: service unavailable")
		return returned[2]
	})

	err := g.Wait()
	for i, name := range names {
		fmt.Printf("   %-8s returned:  %v\n", name, returned[i])
	}
	fmt.Printf("   Wait returned:     %v\n", err)
	fmt.Printf("   ctx.Err():         %v\n", ctx.Err())
	fmt.Printf("   context.Cause:     %v\n", context.Cause(ctx))

	fmt.Println("2. no task fails")
	g, ctx = withContext(context.Background())
	for range 3 {
		g.Go(func() error { return nil })
	}
	fmt.Printf("   ctx.Err() before:  %v\n", ctx.Err())
	fmt.Printf("   Wait returned:     %v\n", g.Wait())
	fmt.Printf("   ctx.Err() after:   %v\n", ctx.Err())
}
