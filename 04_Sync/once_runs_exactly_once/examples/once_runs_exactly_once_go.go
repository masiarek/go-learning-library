// sync.Once, and the three functions built on it: ten goroutines ask for the
// configuration at the same moment, and it is loaded exactly once.
//
//	go build once_runs_exactly_once_go.go && ./once_runs_exactly_once_go
package main

import (
	"fmt"
	"strconv"
	"sync"
	"sync/atomic"
)

const callers = 10

// together starts callers goroutines, releases them at the same moment, and
// waits for all of them. Each gets its own index.
func together(work func(i int)) {
	var wg sync.WaitGroup
	start := make(chan struct{})
	for i := range callers {
		wg.Go(func() {
			<-start
			work(i)
		})
	}
	close(start)
	wg.Wait()
}

func main() {
	// sync.Once: Do runs its function on the first call only. Every other call
	// waits until that one has returned, so reading config after Do is safe.
	var (
		once   sync.Once
		loads  atomic.Int64
		config map[string]string
	)
	loadConfig := func() {
		loads.Add(1)
		config = map[string]string{"listen": ":8080"}
	}
	seen := make([]string, callers)
	together(func(i int) {
		once.Do(loadConfig)
		seen[i] = config["listen"]
	})
	fmt.Println("sync.Once")
	fmt.Println("  calls to Do:           ", callers)
	fmt.Println("  times loadConfig ran:  ", loads.Load())
	fmt.Println("  callers that saw :8080:", count(seen, ":8080"))

	// sync.OnceValue: the same, for a function that returns a value.
	var reads atomic.Int64
	listenAddr := sync.OnceValue(func() string {
		reads.Add(1)
		return ":8080"
	})
	together(func(i int) { seen[i] = listenAddr() })
	fmt.Println("sync.OnceValue")
	fmt.Println("  calls:                 ", callers)
	fmt.Println("  times the function ran:", reads.Load())
	fmt.Println("  callers that got :8080:", count(seen, ":8080"))

	// sync.OnceValues: two results, usually a value and an error. An error is
	// remembered like any other result: the function is not tried again.
	var parses atomic.Int64
	port := sync.OnceValues(func() (int, error) {
		parses.Add(1)
		return strconv.Atoi("80x")
	})
	together(func(i int) {
		_, err := port()
		seen[i] = fmt.Sprint(err)
	})
	fmt.Println("sync.OnceValues")
	fmt.Println("  calls:                 ", callers)
	fmt.Println("  times the function ran:", parses.Load())
	fmt.Println("  error every caller got:", seen[0])
	fmt.Println("  callers that got it:   ", count(seen, seen[0]))
}

func count(values []string, want string) int {
	n := 0
	for _, v := range values {
		if v == want {
			n++
		}
	}
	return n
}
