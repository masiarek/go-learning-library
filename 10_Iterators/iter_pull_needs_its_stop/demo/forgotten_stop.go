// What a forgotten stop leaves behind. iter.Pull runs the iterator on a
// coroutine, which the runtime lists as a goroutine in state [coroutine].
// Without stop it stays there, and a garbage collection does not remove it.
// The goroutine numbers change from run to run, which is why this is a demo
// and not an example.
//
//	go run demo/forgotten_stop.go     # from the lesson folder
package main

import (
	"fmt"
	"iter"
	"runtime"
	"strings"
)

func Orders(yield func(string) bool) {
	defer fmt.Println("producer: deferred cleanup ran")
	for _, o := range []string{"order-1", "order-2", "order-3"} {
		if !yield(o) {
			return
		}
	}
}

// goroutines lists the header line of every goroutine the runtime reports.
func goroutines() string {
	buf := make([]byte, 1<<16)
	n := runtime.Stack(buf, true)
	var headers []string
	for line := range strings.Lines(string(buf[:n])) {
		if strings.HasPrefix(line, "goroutine ") {
			headers = append(headers, strings.TrimSpace(line))
		}
	}
	return strings.Join(headers, " | ")
}

func main() {
	fmt.Println("before:            ", runtime.NumGoroutine(), goroutines())
	next, stop := iter.Pull(iter.Seq[string](Orders))
	next()
	fmt.Println("after one next:    ", runtime.NumGoroutine(), goroutines())
	stop()
	fmt.Println("after stop:        ", runtime.NumGoroutine(), goroutines())

	next, _ = iter.Pull(iter.Seq[string](Orders))
	next()
	runtime.GC()
	fmt.Println("forgot stop, GC ran:", runtime.NumGoroutine(), goroutines())
}
