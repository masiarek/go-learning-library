// a_mutex_guards_a_counter_go.go without the mutex: eight goroutines each add
// 100,000 to one int, and increments are lost. How many varies from run to run,
// which is why this program is here in demo/ and not in examples/.
//
//	bash demo/tally.sh          # from the lesson folder
package main

import (
	"fmt"
	"sync"
)

const (
	workers   = 8
	perWorker = 100_000
)

func main() {
	count := 0
	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for range perWorker {
				count++ // read, add, write: another goroutine can run between any two
			}
		})
	}
	wg.Wait()
	fmt.Printf("%d of %d\n", count, workers*perWorker)
}
