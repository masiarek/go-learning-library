// An unbuffered channel is a handshake: a send does not complete until a
// receiver takes the value. This program hands one order to a packer goroutine
// and asks the runtime where main was waiting when the packer came to receive
// it -- first on an unbuffered channel, then on a channel with room for one.
//
//	go build an_unbuffered_send_waits_for_a_receiver_go.go && ./an_unbuffered_send_waits_for_a_receiver_go
package main

import (
	"fmt"
	"runtime"
	"strings"
	"time"
)

func main() {
	handOff(make(chan string))
	handOff(make(chan string, 1))
}

// handOff sends one order to a packer and waits for the packer's receipt.
func handOff(orders chan string) {
	receipts := make(chan string) // unbuffered: main waits here until the packer replies
	var seen string               // the packer writes it before its receive; main reads it after the receipt

	go func() {
		// Before taking the order, look at where main is waiting.
		seen = waitingOnChannel("main.handOff")
		order := <-orders
		receipts <- "packed " + order
	}()

	orders <- "order-17"
	receipt := <-receipts

	fmt.Printf("orders with cap %d:\n", cap(orders))
	fmt.Printf("  when the packer came to receive, main was parked in [%s]\n", seen)
	fmt.Printf("  main got back %q\n", receipt)
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
			_, state, _ := strings.Cut(header, "[") // "goroutine 1 [chan send]:"
			state, _, _ = strings.Cut(state, "]")
			state, _, _ = strings.Cut(state, ",") // a long wait reads "chan send, 2 minutes"
			if strings.HasPrefix(state, "chan ") {
				return state
			}
		}
		time.Sleep(time.Millisecond)
	}
}
