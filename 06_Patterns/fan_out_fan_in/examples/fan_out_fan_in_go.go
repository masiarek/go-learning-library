// Fan-out, fan-in. Three digesters read words from one channel (fan-out): each
// word goes to exactly one of them. Each digester sends on a channel of its own,
// and merge copies all three onto a single channel, which it closes once every
// input is closed and drained (fan-in). Digests arrive in whatever order the
// digesters finished, so main sorts them before it prints.
//
//	go build fan_out_fan_in_go.go && ./fan_out_fan_in_go
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"slices"
	"strings"
	"sync"
)

type digest struct {
	word string
	sum  string // the first 4 bytes of the word's SHA-256, in hex
}

// words is the source: it sends each word and closes its channel.
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

// digester is one worker. It owns its output channel and closes it when its
// input is closed.
func digester(in <-chan string) <-chan digest {
	out := make(chan digest)
	go func() {
		defer close(out)
		for w := range in {
			sum := sha256.Sum256([]byte(w))
			out <- digest{word: w, sum: hex.EncodeToString(sum[:4])}
		}
	}()
	return out
}

// merge starts one copying goroutine per input, and one more that closes the
// output after every copy has finished, so that no send can follow the close.
func merge(inputs ...<-chan digest) <-chan digest {
	out := make(chan digest)
	var copies sync.WaitGroup
	for _, in := range inputs {
		copies.Go(func() {
			for d := range in {
				out <- d
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
	list := []string{"goroutine", "channel", "select", "mutex", "context", "pipeline", "worker", "semaphore"}
	in := words(list...)

	// Fan-out: three digesters share one input channel.
	a, b, c := digester(in), digester(in), digester(in)

	// Fan-in: one channel, closed when all three are done.
	var got []digest
	for d := range merge(a, b, c) {
		got = append(got, d)
	}

	fmt.Printf("words sent:        %d\n", len(list))
	fmt.Printf("digests received:  %d\n", len(got))

	// Arrival order is the scheduler's; the report's order is main's.
	slices.SortFunc(got, func(x, y digest) int { return strings.Compare(x.word, y.word) })
	fmt.Println("sorted by word:")
	for _, d := range got {
		fmt.Printf("  %-10s %s\n", d.word, d.sum)
	}
}
