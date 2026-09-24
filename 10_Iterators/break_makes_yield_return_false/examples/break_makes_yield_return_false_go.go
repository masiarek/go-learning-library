// break, return and a panic in the loop body all end the iterator's call to
// yield -- with false, or by unwinding through it -- and the iterator's
// deferred cleanup runs before the code after the loop does. A defer written
// in the loop body belongs to the function around the loop, as it reads.
//
//	go build break_makes_yield_return_false_go.go && ./break_makes_yield_return_false_go
package main

import "fmt"

// Orders yields three orders and reports what each yield returned. Its
// deferred line stands in for a cleanup: closing a file, releasing a lock.
func Orders(yield func(string) bool) {
	defer fmt.Println("producer: deferred cleanup ran")
	for _, o := range []string{"order-1", "order-2", "order-3"} {
		ok := yield(o)
		fmt.Printf("producer: yield(%q) returned %t\n", o, ok)
		if !ok {
			return
		}
	}
}

// firstUrgent returns from inside the loop. To the iterator, that is a break.
func firstUrgent() string {
	for o := range Orders {
		if o == "order-2" {
			return o
		}
	}
	return "none"
}

func main() {
	fmt.Println("-- continue: yield returns true")
	for o := range Orders {
		if o == "order-2" {
			continue
		}
		fmt.Println("loop: got", o)
	}

	fmt.Println("-- break: yield returns false")
	for o := range Orders {
		fmt.Println("loop: got", o)
		if o == "order-2" {
			break
		}
	}

	fmt.Println("-- return from the enclosing function")
	fmt.Println("main: firstUrgent returned", firstUrgent())

	fmt.Println("-- panic in the loop body")
	func() {
		defer func() { fmt.Println("main: recovered:", recover()) }()
		for o := range Orders {
			if o == "order-2" {
				panic("cannot pack " + o)
			}
			fmt.Println("loop: got", o)
		}
	}()

	fmt.Println("-- defer in the loop body belongs to main")
	for o := range Orders {
		defer fmt.Println("main: deferred in the body for", o)
	}
	fmt.Println("main: the loop ended, main is still running")
}
