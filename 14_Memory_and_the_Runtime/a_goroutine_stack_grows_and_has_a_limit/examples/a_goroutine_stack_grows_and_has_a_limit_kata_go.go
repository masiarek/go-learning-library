// Kata: sum a linked list of 500,000 invoices with a plain recursive
// function, the kind that would overflow a fixed 8 MB stack in C at a few
// dozen bytes a frame. Print the count and the total, and show that the
// stack limit you set for the goroutine is the one SetMaxStack hands back
// on the next call.
//
//	go build a_goroutine_stack_grows_and_has_a_limit_kata_go.go && ./a_goroutine_stack_grows_and_has_a_limit_kata_go
package main

import (
	"fmt"
	"runtime/debug"
)

type Invoice struct {
	Cents int64
	Next  *Invoice
}

// sum is deliberately recursive: one frame per invoice.
func sum(inv *Invoice) (count int, cents int64) {
	if inv == nil {
		return 0, 0
	}
	count, cents = sum(inv.Next)
	return count + 1, cents + inv.Cents
}

func main() {
	var head *Invoice
	for i := 1; i <= 500000; i++ {
		head = &Invoice{Cents: int64(i%100) + 1, Next: head}
	}

	previous := debug.SetMaxStack(256 << 20)
	fmt.Println("limit before the kata, bytes:", previous)
	count, cents := sum(head)
	fmt.Println("invoices:", count, " total cents:", cents)
	fmt.Println("SetMaxStack hands back the 256 MiB that was set:", debug.SetMaxStack(previous) == 256<<20)
}
