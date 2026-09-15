#!/usr/bin/env bash
# A panic in a goroutine that main started. main is healthy -- it is waiting
# for a total -- and it has a deferred recover, yet the whole process exits
# with status 2. The stack trace under the panic line names a goroutine number
# and addresses that change between runs, so the script keeps stdout, the
# `panic:` line from stderr, and the exit status.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/prices.go" <<'GO'
package main

import "fmt"

func sumPrices(prices []int) (cents int) {
	for i := 0; i <= len(prices); i++ { // one step too far
		cents += prices[i]
	}
	return cents
}

func main() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println("main:   recovered:", r)
		}
	}()
	defer fmt.Println("main:   deferred call")

	totals := make(chan int)
	fmt.Println("main:   starting the worker")
	go func() {
		defer fmt.Println("worker: deferred call runs as the panic unwinds")
		totals <- sumPrices([]int{1999, 450, 1200})
	}()

	fmt.Println("main:   total", <-totals)
}
GO

say() { printf '$ %s\n' "$*"; }

cd "$dir" || exit 1
say 'go build prices.go'
go build prices.go || exit 1

say './prices'
./prices 2>stderr.txt
status=$?
grep '^panic: ' stderr.txt
echo "exit status $status"
