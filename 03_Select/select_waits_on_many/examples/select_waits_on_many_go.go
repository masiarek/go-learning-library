// A select waits on several channel operations at once and carries out exactly
// one of them. A default case turns it into a send or receive that never waits.
//
//	go run select_waits_on_many_go.go
package main

import "fmt"

func main() {
	fmt.Println("1. One select, two channels: it waits until either can proceed")
	temperatures := make(chan int)
	humidities := make(chan int)
	go func() {
		for _, celsius := range []int{21, 22, 23} {
			temperatures <- celsius
		}
	}()
	go func() {
		for _, percent := range []int{40, 45, 50, 55} {
			humidities <- percent
		}
	}()
	fromTemperatures, fromHumidities := 0, 0
	for range 7 {
		select { // blocks until one of the two senders is ready
		case <-temperatures:
			fromTemperatures++
		case <-humidities:
			fromHumidities++
		}
	}
	fmt.Printf("   7 selects: %d from temperatures, %d from humidities\n", fromTemperatures, fromHumidities)

	fmt.Println()
	fmt.Println("2. default: a receive that does not wait")
	jobs := make(chan string, 1)
	tryReceive := func() {
		select {
		case job := <-jobs:
			fmt.Println("   received:", job)
		default:
			fmt.Println("   no job waiting, so default ran")
		}
	}
	tryReceive()
	jobs <- "resize image"
	tryReceive()

	fmt.Println()
	fmt.Println("3. default: a send that does not wait")
	queue := make(chan string, 2)
	for _, order := range []string{"order-1", "order-2", "order-3"} {
		select {
		case queue <- order:
			fmt.Println("   queued: ", order)
		default:
			fmt.Println("   dropped:", order, "(the buffer of 2 is full)")
		}
	}
	handoff := make(chan string) // unbuffered, and no goroutine is receiving
	select {
	case handoff <- "order-4":
		fmt.Println("   handed over: order-4")
	default:
		fmt.Println("   dropped: order-4 (nobody waiting on the unbuffered channel)")
	}

	fmt.Println()
	fmt.Println("4. Every case is evaluated on entry, whichever case is chosen")
	invoices := make(chan string, 1)
	invoices <- "invoice-7"
	select {
	case handoff <- label("order-5"): // cannot proceed: nobody is receiving
		fmt.Println("   sent order-5")
	case invoice := <-invoices:
		fmt.Println("   chose the receive:", invoice)
	}
}

// label announces that it ran, so the output shows when select evaluated it.
func label(order string) string {
	fmt.Println("   label(" + order + ") ran")
	return order
}
