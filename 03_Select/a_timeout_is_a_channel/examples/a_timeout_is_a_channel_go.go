// time.After returns a channel that delivers once a duration has passed, so a
// timeout is one more select case. A Timer is that channel with a Stop, and a
// Ticker is a channel that delivers again and again.
//
//	go run a_timeout_is_a_channel_go.go
package main

import (
	"fmt"
	"time"
)

// forecast answers after delay. Its channel has room for the answer, so a lookup
// that nobody waits for any more can still send, and its goroutine can end.
func forecast(city string, delay time.Duration) <-chan string {
	answer := make(chan string, 1)
	go func() {
		time.Sleep(delay)
		answer <- city + ": 21 C"
	}()
	return answer
}

func main() {
	fmt.Println("1. time.After: a timeout is a select case")
	select {
	case report := <-forecast("Oslo", 0):
		fmt.Println("   answer arrived first:", report)
	case <-time.After(2 * time.Second):
		fmt.Println("   gave up on Oslo")
	}

	start := time.Now()
	select {
	case report := <-forecast("Lima", 3*time.Second):
		fmt.Println("   answer arrived first:", report)
	case <-time.After(1 * time.Second):
		waited := time.Since(start)
		fmt.Println("   gave up on Lima")
		fmt.Println("   waited at least 1s:                  ", waited >= 1*time.Second)
		fmt.Println("   and less than the 3s Lima would take:", waited < 3*time.Second)
	}

	fmt.Println()
	fmt.Println("2. time.NewTimer: the same channel, with a Stop")
	timer := time.NewTimer(10 * time.Millisecond)
	fmt.Println("   cap(timer.C) =", cap(timer.C))
	time.Sleep(2 * time.Second) // a margin: the timer is long past due, and nobody received
	timer.Stop()
	select {
	case <-timer.C:
		fmt.Println("   received a stale time after Stop")
	default:
		fmt.Println("   nothing to receive after Stop")
	}

	fmt.Println()
	fmt.Println("3. time.NewTicker: a channel that delivers again and again")
	ticker := time.NewTicker(100 * time.Millisecond)
	deadline := time.After(2500 * time.Millisecond)
	ticks := 0
	for ticks < 3 {
		select {
		case <-ticker.C:
			ticks++
			fmt.Println("   tick", ticks)
		case <-deadline:
			fmt.Println("   deadline passed after", ticks, "ticks")
			return
		}
	}
	ticker.Stop()
	select {
	case <-ticker.C:
		fmt.Println("   a tick arrived after Stop")
	default:
		fmt.Println("   no tick after Stop")
	}
}
