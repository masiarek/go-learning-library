// A pipeline of stages: count -> square -> main. Each stage is a goroutine that
// owns its output channel: it is the only sender on it, and it closes it on its
// way out. A context tells the stages to stop early, so that none is left
// blocked on a send that nobody will ever receive.
//
//	go build a_pipeline_of_stages_go.go && ./a_pipeline_of_stages_go
package main

import (
	"context"
	"fmt"
	"math"
	"sync"
)

// count is the first stage, the source: it sends 1, 2, ... last, then closes
// its channel. It stops early if ctx is canceled.
func count(ctx context.Context, stages *sync.WaitGroup, last int) <-chan int {
	out := make(chan int)
	stages.Go(func() {
		defer close(out) // the owner closes, on every way out
		for n := 1; n <= last; n++ {
			select {
			case out <- n:
			case <-ctx.Done():
				return
			}
		}
	})
	return out
}

// square is a middle stage: it receives until its input is closed, sends the
// square of each value, and closes its own channel when it returns.
func square(ctx context.Context, stages *sync.WaitGroup, in <-chan int) <-chan int {
	out := make(chan int)
	stages.Go(func() {
		defer close(out)
		for n := range in {
			select {
			case out <- n * n:
			case <-ctx.Done():
				return
			}
		}
	})
	return out
}

func main() {
	var stages sync.WaitGroup // counts the stage goroutines, to prove they returned

	fmt.Println("1. count(1..5) -> square -> main reads to the end")
	ctx := context.Background()
	squares := square(ctx, &stages, count(ctx, &stages, 5))
	var got []int
	for s := range squares { // ends when square closes its channel
		got = append(got, s)
	}
	fmt.Println("   main received: ", got)
	stages.Wait()
	fmt.Println("   stages.Wait()   returned: count and square have ended")

	fmt.Println("2. count(1..) -> square -> main reads 3, then cancels")
	ctx, cancel := context.WithCancel(context.Background())
	squares = square(ctx, &stages, count(ctx, &stages, math.MaxInt))
	got = nil
	for range 3 {
		got = append(got, <-squares)
	}
	fmt.Println("   main received: ", got)
	cancel()
	stages.Wait()
	fmt.Println("   stages.Wait()   returned: count and square have ended")
	_, open := <-squares
	fmt.Println("   squares open:  ", open)
}
