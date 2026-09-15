// What the lesson's answer key cannot record: how long it takes to start n
// goroutines that block, how much memory they hold while blocked, and how many
// goroutines runtime.NumGoroutine still reports the moment Wait returns.
//
//	go run cost.go 100000
package main

import (
	"fmt"
	"os"
	"runtime"
	"strconv"
	"sync"
	"time"
)

func main() {
	n := 100_000
	if len(os.Args) > 1 {
		var err error
		if n, err = strconv.Atoi(os.Args[1]); err != nil || n < 1 {
			fmt.Fprintln(os.Stderr, "usage: cost [number of goroutines]")
			os.Exit(2)
		}
	}

	var before, during runtime.MemStats
	runtime.GC()
	runtime.ReadMemStats(&before)

	release := make(chan struct{})
	var started, finished sync.WaitGroup
	started.Add(n)
	begin := time.Now()
	for range n {
		finished.Go(func() {
			started.Done()
			<-release
		})
	}
	started.Wait()
	elapsed := time.Since(begin)
	runtime.ReadMemStats(&during)

	close(release)
	finished.Wait()
	leftAtWait := runtime.NumGoroutine()

	// One row; cost.sh prints the header.
	perGoroutine := func(bytes uint64) float64 { return float64(bytes) / 1024 / float64(n) }
	fmt.Printf("%10d %13.1f %15.2f %17.2f %21d\n",
		n,
		float64(elapsed.Microseconds())/1000,
		perGoroutine(during.StackInuse-before.StackInuse),
		perGoroutine(during.Sys-before.Sys),
		leftAtWait)
}
