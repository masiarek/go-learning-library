// A send or receive on a nil channel blocks forever, so a select case on a nil
// channel can never be chosen. Setting a channel variable to nil switches its
// case off -- which is how a loop merges two channels until both are closed.
//
//	go run a_nil_channel_disables_a_case_go.go
package main

import (
	"fmt"
	"slices"
)

func main() {
	fmt.Println("1. A closed channel is always ready; a nil channel never is")
	orders := make(chan string)
	close(orders)
	fmt.Println("   closed channel: case chosen", chosen(orders), "of 1000 times")
	orders = nil
	fmt.Println("   nil channel:    case chosen", chosen(orders), "of 1000 times")

	fmt.Println()
	fmt.Println("2. Merging two channels until both are closed")
	temperatures := readings("temperature", 3)
	humidities := readings("humidity", 4)
	var merged []string
	selects := 0
	for temperatures != nil || humidities != nil {
		selects++
		select {
		case reading, ok := <-temperatures:
			if !ok {
				temperatures = nil // closed: switch this case off
				continue
			}
			merged = append(merged, reading)
		case reading, ok := <-humidities:
			if !ok {
				humidities = nil
				continue
			}
			merged = append(merged, reading)
		}
	}
	slices.Sort(merged) // arrival order varies; print in an order that does not
	for _, reading := range merged {
		fmt.Println("  ", reading)
	}
	fmt.Println("   selects:", selects, "=", len(merged), "readings + 2 closes")
}

// chosen runs 1000 non-blocking selects on ch and counts how often its case won.
func chosen(ch chan string) int {
	count := 0
	for range 1000 {
		select {
		case <-ch:
			count++
		default:
		}
	}
	return count
}

// readings sends n readings of one kind, then closes the channel.
func readings(kind string, n int) <-chan string {
	out := make(chan string)
	go func() {
		defer close(out)
		for i := range n {
			out <- fmt.Sprintf("%s reading %d", kind, i+1)
		}
	}()
	return out
}
