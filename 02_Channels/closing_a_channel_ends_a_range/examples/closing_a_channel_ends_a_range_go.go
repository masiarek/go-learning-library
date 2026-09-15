// close is how a sender says "no more values". A range over the channel ends,
// and every receive after the last value returns at once with the zero value
// and ok == false. Sending on a closed channel, or closing it again, panics.
//
//	go build closing_a_channel_ends_a_range_go.go && ./closing_a_channel_ends_a_range_go
package main

import "fmt"

func main() {
	readings := make(chan int)
	go sensor(readings, []int{21, 19, 23})

	for r := range readings {
		fmt.Println("range: received", r)
	}
	fmt.Println("range: ended, because the sensor closed the channel")

	for range 2 {
		r, ok := <-readings
		fmt.Printf("receive after close: r = %d, ok = %t\n", r, ok)
	}

	// close does not throw away values already in a buffer.
	orders := make(chan string, 2)
	orders <- "order-1"
	orders <- "order-2"
	close(orders)
	for range 3 {
		order, ok := <-orders
		fmt.Printf("closed with 2 in the buffer: %q, ok = %t\n", order, ok)
	}

	fmt.Println("send on a closed channel: panic:", panicOf(func() { orders <- "order-3" }))
	fmt.Println("close a closed channel:   panic:", panicOf(func() { close(orders) }))
	var unmade chan string
	fmt.Println("close a nil channel:      panic:", panicOf(func() { close(unmade) }))
}

// sensor is the only sender on out, so it is the one that closes it.
func sensor(out chan<- int, values []int) {
	defer close(out)
	for _, v := range values {
		out <- v
	}
}

// panicOf runs f and returns the value it panicked with, recovered in this goroutine.
func panicOf(f func()) (value any) {
	defer func() { value = recover() }()
	f()
	return "none"
}
