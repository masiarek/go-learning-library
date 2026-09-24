#!/usr/bin/env bash
# What the compiler does with each defer statement, in its own words. The
# debug flag -d=defer prints one line per defer. Two defers in a plain
# function are open-coded -- the call is placed inline at every return, the
# fast path since Go 1.14. Nine of them are over the limit of eight and fall
# back to a record on the stack. A defer inside a loop needs a record on the
# heap, because how many will run is not known until run time.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/kinds.go" <<'GO'
package main

import (
	"fmt"
	"os"
)

// twoDefers: at most eight defers and none in a loop -> open-coded.
func twoDefers() {
	f, err := os.CreateTemp("", "orders-*.csv")
	if err != nil {
		return
	}
	defer os.Remove(f.Name())
	defer f.Close()
	fmt.Fprintln(f, "order-1")
}

// nineDefers: one over the open-coding limit -> a record on the stack.
func nineDefers() {
	defer fmt.Println("step 1")
	defer fmt.Println("step 2")
	defer fmt.Println("step 3")
	defer fmt.Println("step 4")
	defer fmt.Println("step 5")
	defer fmt.Println("step 6")
	defer fmt.Println("step 7")
	defer fmt.Println("step 8")
	defer fmt.Println("step 9")
}

// deferInLoop: how many defers run is decided at run time -> records on the heap.
func deferInLoop(paths []string) {
	for _, path := range paths {
		f, err := os.Open(path)
		if err != nil {
			return
		}
		defer f.Close()
	}
}

func main() {
	twoDefers()
	nineDefers()
	deferInLoop(nil)
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go build -gcflags=-d=defer kinds.go'
go build -gcflags=-d=defer kinds.go 2>&1
echo "exit status $?"
