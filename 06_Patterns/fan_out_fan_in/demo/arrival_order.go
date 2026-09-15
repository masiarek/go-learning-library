// fan_out_fan_in_go.go without the sort: it prints the words on one line, in
// the order their digests came out of merge. demo/tally.sh runs it many times.
package main

import (
	"crypto/sha256"
	"fmt"
	"strings"
	"sync"
)

func words(list ...string) <-chan string {
	out := make(chan string)
	go func() {
		defer close(out)
		for _, w := range list {
			out <- w
		}
	}()
	return out
}

func digester(in <-chan string) <-chan string {
	out := make(chan string)
	go func() {
		defer close(out)
		for w := range in {
			_ = sha256.Sum256([]byte(w))
			out <- w
		}
	}()
	return out
}

func merge(inputs ...<-chan string) <-chan string {
	out := make(chan string)
	var copies sync.WaitGroup
	for _, in := range inputs {
		copies.Go(func() {
			for w := range in {
				out <- w
			}
		})
	}
	go func() {
		copies.Wait()
		close(out)
	}()
	return out
}

func main() {
	in := words("goroutine", "channel", "select", "mutex", "context", "pipeline", "worker", "semaphore")
	a, b, c := digester(in), digester(in), digester(in)
	var order []string
	for w := range merge(a, b, c) {
		order = append(order, w)
	}
	fmt.Println(strings.Join(order, " "))
}
