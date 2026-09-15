// The leak without the gate: 1000 callers at once, each with a 5ms timeout,
// against a supplier that takes 5ms to answer on an unbuffered channel. Whether
// a caller is still listening when its answer comes is a race, so the number of
// goroutines left blocked a second later changes from run to run.
//
// Not run by CI. demo/tally.sh builds it and runs it many times.
package main

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"time"
)

func fetch(ctx context.Context) (int, error) {
	prices := make(chan int)
	go func() {
		time.Sleep(5 * time.Millisecond)
		prices <- 1299
	}()
	select {
	case p := <-prices:
		return p, nil
	case <-ctx.Done():
		return 0, ctx.Err()
	}
}

func main() {
	var wg sync.WaitGroup
	for range 1000 {
		wg.Go(func() {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Millisecond)
			defer cancel()
			_, _ = fetch(ctx)
		})
	}
	wg.Wait()
	time.Sleep(time.Second) // a margin: every answer that was coming has come
	fmt.Println(runtime.NumGoroutine() - 1)
}
