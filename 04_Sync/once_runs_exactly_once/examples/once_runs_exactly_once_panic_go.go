// When the function panics: sync.Once forgets the panic, sync.OnceFunc repeats
// it. Each is called three times, and each runs the function once.
//
// The program recovers each panic only so that it can print it.
//
//	go build once_runs_exactly_once_panic_go.go && ./once_runs_exactly_once_panic_go
package main

import (
	"fmt"
	"sync"
)

// recovered calls f and returns the value it panicked with, or nil.
func recovered(f func()) (value any) {
	defer func() { value = recover() }()
	f()
	return nil
}

func main() {
	runs := 0
	loadConfig := func() {
		runs++
		panic("config file missing")
	}

	var once sync.Once
	fmt.Println("once.Do(loadConfig)")
	for call := 1; call <= 3; call++ {
		fmt.Printf("  call %d: panic = %v\n", call, recovered(func() { once.Do(loadConfig) }))
	}
	fmt.Println("  loadConfig ran:", runs)

	runs = 0
	load := sync.OnceFunc(loadConfig)
	fmt.Println("load := sync.OnceFunc(loadConfig)")
	for call := 1; call <= 3; call++ {
		fmt.Printf("  call %d: panic = %v\n", call, recovered(load))
	}
	fmt.Println("  loadConfig ran:", runs)
}
