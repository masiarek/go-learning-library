#!/usr/bin/env bash
# The worker pool with one change: main sends every job itself before it reads
# any result. Each of the three workers takes one job, then blocks sending its
# result, because main is not receiving; main blocks sending the fourth job,
# because no worker is receiving. Once every goroutine is blocked, Go's runtime
# ends the program. The goroutine dump after its first line names goroutine
# numbers, so this script keeps the first line and the exit status.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/deadlock.go" <<'GO'
package main

import (
	"fmt"
	"strings"
	"sync"
)

func main() {
	lines := []string{
		"a goroutine is a function running concurrently",
		"a channel carries values between goroutines",
		"close the jobs channel once every job is sent",
		"each worker returns when its range loop ends",
		"results are stored by job index",
		"so the report keeps the order of the input",
	}
	jobs := make(chan string)
	results := make(chan int)

	var pool sync.WaitGroup
	for range 3 {
		pool.Go(func() {
			for line := range jobs {
				results <- len(strings.Fields(line))
			}
		})
	}

	for i, line := range lines { // every job first...
		jobs <- line
		fmt.Printf("main: sent job %d\n", i+1)
	}
	close(jobs)
	for words := range results { // ...then the results: never reached
		fmt.Println(words)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build deadlock.go'
(cd "$dir" && go build -trimpath deadlock.go) || exit 1

say './deadlock'
(cd "$dir" && ./deadlock) 2>"$dir/stderr"
status=$?
grep '^fatal error' "$dir/stderr"
echo "exit status $status"
