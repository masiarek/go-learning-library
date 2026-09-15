// make(chan T, n) is a queue with room for n values. A send succeeds without a
// receiver until the buffer is full, and then blocks until a receiver makes
// room. That block is backpressure: a producer can get at most n values ahead
// of whoever is receiving.
//
//	go build a_buffered_channel_is_a_bounded_queue_go.go && ./a_buffered_channel_is_a_bounded_queue_go
package main

import (
	"fmt"
	"runtime"
	"strings"
	"sync/atomic"
	"time"
)

func main() {
	fmt.Println("one goroutine, no receiver:")
	jobs := make(chan string, 3)
	fmt.Printf("  made        len %d  cap %d\n", len(jobs), cap(jobs))
	for i := 1; i <= 3; i++ {
		jobs <- fmt.Sprintf("job-%d", i)
		fmt.Printf("  sent job-%d  len %d  cap %d\n", i, len(jobs), cap(jobs))
	}
	for range 3 {
		job := <-jobs
		fmt.Printf("  took %s  len %d  cap %d\n", job, len(jobs), cap(jobs))
	}

	const total = 7
	fmt.Printf("\na producer with %d jobs, and main taking one only when the producer is stuck:\n", total)
	queue := make(chan string, 3)
	var sent atomic.Int64
	go produce(queue, total, &sent)

	for taken := 0; taken+cap(queue) < total; taken++ {
		state := waitingOnChannel("main.produce")
		fmt.Printf("  producer parked in [%s] after %d sends, len %d\n", state, sent.Load(), len(queue))
		fmt.Printf("  main took %s\n", <-queue)
	}
	for job := range queue {
		fmt.Printf("  main took %s\n", job)
	}
	fmt.Printf("  producer closed the queue after %d sends\n", sent.Load())
}

// produce sends total jobs as fast as the queue lets it, then closes the queue.
func produce(queue chan<- string, total int, sent *atomic.Int64) {
	for i := 1; i <= total; i++ {
		queue <- fmt.Sprintf("job-%d", i)
		sent.Add(1)
	}
	close(queue)
}

// waitingOnChannel returns the runtime's own word for why the goroutine running
// fn is parked on a channel: "chan send" or "chan receive". It reads the same
// goroutine dump that a crash prints, and polls until that goroutine is parked
// on a channel; the sleep between polls only keeps the loop from spinning.
func waitingOnChannel(fn string) string {
	buf := make([]byte, 1<<16)
	for {
		n := runtime.Stack(buf, true)
		for _, g := range strings.Split(string(buf[:n]), "\n\n") {
			header, frames, _ := strings.Cut(g, "\n")
			if !strings.Contains("\n"+frames, "\n"+fn+"(") {
				continue
			}
			_, state, _ := strings.Cut(header, "[") // "goroutine 7 [chan send]:"
			state, _, _ = strings.Cut(state, "]")
			state, _, _ = strings.Cut(state, ",") // a long wait reads "chan send, 2 minutes"
			if strings.HasPrefix(state, "chan ") {
				return state
			}
		}
		time.Sleep(time.Millisecond)
	}
}
