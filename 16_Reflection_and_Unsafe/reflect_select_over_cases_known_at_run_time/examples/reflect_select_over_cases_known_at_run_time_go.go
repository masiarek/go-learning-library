// reflect.Select is a select statement whose cases are a slice built at run
// time. It returns the index of the case it took, the received Value, and
// whether that value came from a send (false: the channel is closed).
//
//	go build reflect_select_over_cases_known_at_run_time_go.go && ./reflect_select_over_cases_known_at_run_time_go
package main

import (
	"fmt"
	"reflect"
	"sort"
	"testing"
)

var sink int

func main() {
	// Four sensors: a number a config file could set, so no select statement can name them.
	sensors := make([]chan int, 4)
	cases := make([]reflect.SelectCase, len(sensors))
	for i := range sensors {
		sensors[i] = make(chan int, 1)
		cases[i] = reflect.SelectCase{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(sensors[i])}
	}

	// One channel ready at a time: the chosen index is that channel's.
	for i := range sensors {
		sensors[i] <- 20 + i
		chosen, recv, recvOK := reflect.Select(cases)
		fmt.Printf("sensor %d ready:  chosen %d, value %d, recvOK %t\n", i, chosen, recv.Int(), recvOK)
	}

	// All ready at once: the order is random, so collect and sort.
	for i := range sensors {
		sensors[i] <- 30 + i
	}
	var got []int
	for range sensors {
		_, recv, _ := reflect.Select(cases)
		got = append(got, int(recv.Int()))
	}
	sort.Ints(got)
	fmt.Println("all four ready:  received", got)

	// Nothing ready and a default case: the default's index, and no value.
	chosen, recv, recvOK := reflect.Select(withDefault(cases))
	fmt.Printf("nothing ready:   chosen %d (the default), recv.IsValid %t, recvOK %t\n", chosen, recv.IsValid(), recvOK)

	// A closed channel is always ready: the zero value, and recvOK false.
	close(sensors[2])
	chosen, recv, recvOK = reflect.Select(cases)
	fmt.Printf("sensor 2 closed: chosen %d, value %d, recvOK %t\n", chosen, recv.Int(), recvOK)

	// Switch it off: a nil channel is never ready, and a zero Value Chan is skipped.
	cases[2].Chan = reflect.ValueOf((chan int)(nil))
	chosen, _, _ = reflect.Select(withDefault(cases))
	fmt.Printf("sensor 2 nil:    chosen %d (the default)\n", chosen)
	cases[2].Chan = reflect.Value{}
	chosen, _, _ = reflect.Select(withDefault(cases))
	fmt.Printf("sensor 2 zero:   chosen %d (the default)\n", chosen)

	// A send case: Send holds the value; recv comes back invalid.
	alerts := make(chan string, 1)
	send := []reflect.SelectCase{{Dir: reflect.SelectSend, Chan: reflect.ValueOf(alerts), Send: reflect.ValueOf("sensor 2 offline")}}
	chosen, recv, recvOK = reflect.Select(send)
	fmt.Printf("send case:       chosen %d, recv.IsValid %t, recvOK %t, delivered %q\n", chosen, recv.IsValid(), recvOK, <-alerts)

	// What it costs, in allocations per call, against a select statement.
	a, b := make(chan int, 1), make(chan int, 1)
	two := []reflect.SelectCase{{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(a)}, {Dir: reflect.SelectRecv, Chan: reflect.ValueOf(b)}}
	fmt.Println("allocations per call, select statement, 2 cases:", testing.AllocsPerRun(100, func() {
		a <- 1
		select {
		case v := <-a:
			sink = v
		case v := <-b:
			sink = v
		}
	}))
	fmt.Println("allocations per call, reflect.Select,   2 cases:", testing.AllocsPerRun(100, func() {
		a <- 1
		_, v, _ := reflect.Select(two)
		sink = int(v.Int())
	}))
}

// withDefault returns a copy of cases with a default case appended.
func withDefault(cases []reflect.SelectCase) []reflect.SelectCase {
	out := append([]reflect.SelectCase(nil), cases...)
	return append(out, reflect.SelectCase{Dir: reflect.SelectDefault})
}
