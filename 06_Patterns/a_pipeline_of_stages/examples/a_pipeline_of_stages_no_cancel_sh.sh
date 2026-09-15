#!/usr/bin/env bash
# The pipeline from a_pipeline_of_stages_go.go with the cancellation taken out:
# the stages have no context to watch. main reads three squares and then waits
# for the stages to return, which they never do: each is blocked on a send that
# nothing will receive. Once every goroutine is blocked, Go's runtime ends the
# program. The goroutine dump after its first line names goroutine numbers, so
# this script keeps the first line and the exit status.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/no_cancel.go" <<'GO'
package main

import (
	"fmt"
	"math"
	"sync"
)

func count(stages *sync.WaitGroup, last int) <-chan int {
	out := make(chan int)
	stages.Go(func() {
		defer close(out)
		for n := 1; n <= last; n++ {
			out <- n // no select, no way to stop
		}
	})
	return out
}

func square(stages *sync.WaitGroup, in <-chan int) <-chan int {
	out := make(chan int)
	stages.Go(func() {
		defer close(out)
		for n := range in {
			out <- n * n
		}
	})
	return out
}

func main() {
	var stages sync.WaitGroup
	squares := square(&stages, count(&stages, math.MaxInt))
	for range 3 {
		fmt.Println("main received:", <-squares)
	}
	fmt.Println("main: done reading, waiting for the stages to return")
	stages.Wait()
	fmt.Println("main: the stages returned") // never printed
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build no_cancel.go'
(cd "$dir" && go build -trimpath no_cancel.go) || exit 1

say './no_cancel'
(cd "$dir" && ./no_cancel) 2>"$dir/stderr"
status=$?
grep '^fatal error' "$dir/stderr"
echo "exit status $status"
