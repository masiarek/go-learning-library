// What a panic does to a locked sync.Mutex: nothing. The mutex has no record of
// the panic. If the function that locked it deferred the Unlock, the panic
// unlocks it on the way out; if the Unlock is an ordinary last line, the panic
// skips it and the mutex stays locked.
//
// A panic that nothing recovers ends the whole program, locks and all, so this
// only matters where something recovers: net/http, for one, recovers a panic in
// a handler and keeps serving. recovered below plays that part.
//
// TryLock is used only as a probe, to ask "is it locked?" without blocking.
//
//	go build a_mutex_guards_a_counter_defer_go.go && ./a_mutex_guards_a_counter_defer_go
package main

import (
	"fmt"
	"sync"
)

type account struct {
	mu      sync.Mutex
	balance int
}

// depositDefer unlocks with defer.
func (a *account) depositDefer(amount int) {
	a.mu.Lock()
	defer a.mu.Unlock()
	if amount <= 0 {
		panic(fmt.Sprintf("deposit of %d", amount))
	}
	a.balance += amount
}

// depositLastLine unlocks on its last line, which a panic never reaches.
func (a *account) depositLastLine(amount int) {
	a.mu.Lock()
	if amount <= 0 {
		panic(fmt.Sprintf("deposit of %d", amount))
	}
	a.balance += amount
	a.mu.Unlock()
}

// recovered calls f and returns the value it panicked with, or nil.
func recovered(f func()) (value any) {
	defer func() { value = recover() }()
	f()
	return nil
}

// unlocked reports whether nobody holds mu, leaving it as it found it.
func unlocked(mu *sync.Mutex) bool {
	if mu.TryLock() {
		mu.Unlock()
		return true
	}
	return false
}

func main() {
	var a account
	a.depositDefer(100)
	fmt.Println("defer mu.Unlock():")
	fmt.Println("  recovered panic:     ", recovered(func() { a.depositDefer(-5) }))
	fmt.Println("  unlocked afterwards: ", unlocked(&a.mu))
	a.depositDefer(50) // an ordinary Lock: no error to check, no flag to clear
	fmt.Println("  next deposit, balance:", a.balance)

	var b account
	b.depositLastLine(100)
	fmt.Println("mu.Unlock() on the last line:")
	fmt.Println("  recovered panic:     ", recovered(func() { b.depositLastLine(-5) }))
	fmt.Println("  unlocked afterwards: ", unlocked(&b.mu))
}
