// A goroutine's stack starts small and grows as the calls nest: a descent a
// million frames deep succeeds, and the runtime's stack accounting shows
// the growth. debug.SetMaxStack returns the previous limit, which is
// 1000000000 bytes on a 64-bit machine.
//
//	go build a_goroutine_stack_grows_and_has_a_limit_go.go && ./a_goroutine_stack_grows_and_has_a_limit_go
package main

import (
	"fmt"
	"runtime"
	"runtime/debug"
)

// stackInUse reads the bytes the runtime currently holds in goroutine
// stacks. It is not inlined: MemStats is several kilobytes, and inlined
// into dive it would be part of every one of the million frames.
//
//go:noinline
func stackInUse() uint64 {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return m.StackInuse
}

var atTheBottom uint64

// dive recurses until depth reaches target and reads the stack size there.
func dive(depth, target int) int {
	if depth == target {
		atTheBottom = stackInUse()
		return depth
	}
	return dive(depth+1, target)
}

func main() {
	fmt.Println("SetMaxStack(64<<20) returned the default limit:", debug.SetMaxStack(64<<20))
	fmt.Println("SetMaxStack(1000000000) returned what was just set:", debug.SetMaxStack(1000000000))

	before := stackInUse()
	reached := make(chan int)
	go func() { reached <- dive(0, 1000000) }()
	fmt.Println("depth reached:", <-reached)
	fmt.Println("stack in use grew by more than 8 MB during the descent:", atTheBottom-before > 8<<20)
}
