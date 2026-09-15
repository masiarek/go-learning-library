// The runtime reports a deadlock only when every goroutine is blocked. Here a
// packer and a shipper wait for each other forever, but main is waiting on a
// timer as well, so the runtime reports nothing. After 2 s main gives up and
// asks the runtime where the two are stuck.
//
//	go build all_goroutines_are_asleep_go.go && ./all_goroutines_are_asleep_go
package main

import (
	"fmt"
	"runtime"
	"strings"
	"time"
)

func main() {
	boxes := make(chan string)
	labels := make(chan string)
	shipped := make(chan string)

	go packer(labels, boxes)
	go shipper(boxes, labels, shipped)

	select {
	case parcel := <-shipped:
		fmt.Println("main: shipped", parcel)
	case <-time.After(2 * time.Second):
		fmt.Println("main: nothing shipped after 2 s, and the runtime reported no deadlock")
	}
	fmt.Printf("packer:  parked in [%s]\n", waitingOnChannel("main.packer"))
	fmt.Printf("shipper: parked in [%s]\n", waitingOnChannel("main.shipper"))
}

// packer will not pack a box until it has a shipping label.
func packer(labels <-chan string, boxes chan<- string) {
	label := <-labels
	boxes <- "box with " + label
}

// shipper will not print a label until it has a box.
func shipper(boxes <-chan string, labels chan<- string, shipped chan<- string) {
	box := <-boxes
	labels <- "label-1"
	shipped <- box
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
			_, state, _ := strings.Cut(header, "[") // "goroutine 7 [chan receive]:"
			state, _, _ = strings.Cut(state, "]")
			state, _, _ = strings.Cut(state, ",") // a long wait reads "chan receive, 2 minutes"
			if strings.HasPrefix(state, "chan ") {
				return state
			}
		}
		time.Sleep(time.Millisecond)
	}
}
