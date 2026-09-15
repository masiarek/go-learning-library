// A goroutine blocked on a send that nobody will ever receive never ends. Its
// caller timed out and left; the goroutine it started is still there.
//
//	go build a_leaked_goroutine_never_ends_go.go && ./a_leaked_goroutine_never_ends_go
package main

import (
	"context"
	"fmt"
	"runtime"
	"sort"
	"strings"
	"time"
)

// Each fetch asks a supplier for a price on a goroutine of its own and waits
// for the answer or for ctx, whichever comes first. The supplier answers only
// when late is closed, and main closes it after every caller has given up: so
// the answer is late on every run, not just on a slow machine.

// fetchUnbuffered leaks: once the caller has gone, the send waits forever.
func fetchUnbuffered(ctx context.Context, late <-chan struct{}) (int, error) {
	prices := make(chan int)
	go func() {
		<-late
		prices <- 1299
	}()
	select {
	case p := <-prices:
		return p, nil
	case <-ctx.Done():
		return 0, ctx.Err()
	}
}

// fetchBuffered does not: the send has room for one value and never waits.
func fetchBuffered(ctx context.Context, late <-chan struct{}) (int, error) {
	prices := make(chan int, 1)
	go func() {
		<-late
		prices <- 1299
	}()
	select {
	case p := <-prices:
		return p, nil
	case <-ctx.Done():
		return 0, ctx.Err()
	}
}

// fetchSelect does not either: the goroutine gives up when the caller has.
func fetchSelect(ctx context.Context, late <-chan struct{}) (int, error) {
	prices := make(chan int)
	go func() {
		<-late
		select {
		case prices <- 1299:
		case <-ctx.Done():
		}
	}()
	select {
	case p := <-prices:
		return p, nil
	case <-ctx.Done():
		return 0, ctx.Err()
	}
}

func main() {
	try("unbuffered channel", fetchUnbuffered)
	try("buffered channel of 1", fetchBuffered)
	try("send in a select with ctx.Done()", fetchSelect)

	fmt.Println("main returns with", runtime.NumGoroutine(), "goroutines running:")
	for _, line := range blockedGoroutines() {
		fmt.Println("  " + line)
	}
}

// try runs three callers with a 10ms timeout each, lets the suppliers answer,
// and counts the goroutines that are still there afterwards.
func try(name string, fetch func(context.Context, <-chan struct{}) (int, error)) {
	before := runtime.NumGoroutine()
	late := make(chan struct{})
	errs := map[string]int{}
	for range 3 {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Millisecond)
		_, err := fetch(ctx, late)
		cancel()
		errs[fmt.Sprint(err)]++
	}
	close(late) // the suppliers answer now, and nobody is listening
	fmt.Println(name + ":")
	for err, n := range errs {
		fmt.Printf("  callers: %d × %s\n", n, err)
	}
	fmt.Println("  goroutines left behind:", settle(before)-before)
}

// settle waits until the goroutine count is back down to want, and gives up
// after two seconds. A goroutine that has finished its work can still be
// counted for a moment while it exits, so a single reading could be one high.
func settle(want int) int {
	deadline := time.Now().Add(2 * time.Second)
	for runtime.NumGoroutine() > want && time.Now().Before(deadline) {
		time.Sleep(10 * time.Millisecond)
	}
	return runtime.NumGoroutine()
}

// blockedGoroutines reads every goroutine's stack, as a panic would print it,
// and counts the others by their wait state and the function they are in.
func blockedGoroutines() []string {
	buf := make([]byte, 1<<20)
	traces := strings.Split(string(buf[:runtime.Stack(buf, true)]), "\n\n")
	counts := map[string]int{}
	for _, trace := range traces[1:] { // traces[0] is main itself
		lines := strings.Split(trace, "\n")
		state := lines[0][strings.Index(lines[0], "[") : strings.Index(lines[0], "]")+1]
		function := lines[1][:strings.LastIndex(lines[1], "(")]
		counts[state+" in "+function]++
	}
	var out []string
	for where, n := range counts {
		out = append(out, fmt.Sprintf("%d × %s", n, where))
	}
	sort.Strings(out)
	return out
}
