// Kata: merge any number of order channels into one slice with reflect.Select,
// dropping each channel's case when it closes (recvOK false) so the loop ends
// when every channel has closed. The result is sorted, so the output does not
// depend on which warehouse was fastest.
//
//	go build reflect_select_over_cases_known_at_run_time_kata_go.go && ./reflect_select_over_cases_known_at_run_time_kata_go
package main

import (
	"fmt"
	"reflect"
	"sort"
)

func merge(inputs []<-chan string) (orders []string, rounds int) {
	cases := make([]reflect.SelectCase, len(inputs))
	for i, ch := range inputs {
		cases[i] = reflect.SelectCase{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(ch)}
	}
	for open := len(cases); open > 0; rounds++ {
		i, v, ok := reflect.Select(cases)
		if !ok {
			cases[i].Chan = reflect.Value{} // a zero Chan is ignored from now on
			open--
			continue
		}
		orders = append(orders, v.String())
	}
	sort.Strings(orders)
	return orders, rounds
}

func warehouse(name string, count int) <-chan string {
	out := make(chan string)
	go func() {
		defer close(out)
		for i := 1; i <= count; i++ {
			out <- fmt.Sprintf("%s-order-%d", name, i)
		}
	}()
	return out
}

func main() {
	inputs := []<-chan string{warehouse("east", 2), warehouse("west", 3), warehouse("north", 1)}
	orders, rounds := merge(inputs)
	fmt.Println(len(orders), "orders from", len(inputs), "channels in", rounds, "rounds of reflect.Select")
	for _, o := range orders {
		fmt.Println(" ", o)
	}
}
