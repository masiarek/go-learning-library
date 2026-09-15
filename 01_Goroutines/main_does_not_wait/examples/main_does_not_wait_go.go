// main does not wait. When main returns, the program exits, and a goroutine
// that is still running is stopped where it stands. This one has already
// written three orders -- into a buffered writer. Its deferred Flush never
// runs, so nobody ever sees them.
//
//	go run main_does_not_wait_go.go
package main

import (
	"bufio"
	"fmt"
	"os"
	"time"
)

func main() {
	defer fmt.Println("main:   deferred call runs as main returns")

	written := make(chan struct{})
	go func() {
		out := bufio.NewWriter(os.Stdout)
		defer out.Flush() // would write the three orders out; never runs

		fmt.Println("worker: writing three orders to a buffered writer")
		for _, order := range []string{"A-1001", "A-1002", "A-1003"} {
			fmt.Fprintln(out, "worker: order", order)
		}
		close(written)

		time.Sleep(3 * time.Second)
		fmt.Println("worker: finished")
	}()

	<-written
	fmt.Println("main:   the worker has written its orders; returning")
}
