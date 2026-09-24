#!/usr/bin/env bash
# Three ways to break the yield contract, in one program that takes the
# misuse as its argument, each run with nothing to recover the panic. The
# yield function the compiler synthesizes checks how it is used and panics
# with a message naming the misuse, and the program ends with exit status 2.
# The goroutine trace on stderr carries code offsets, so only the panic lines
# are kept.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/misuse.go" <<'GO'
package main

import (
	"fmt"
	"os"
)

// Careless never looks at what yield returns.
func Careless(yield func(int) bool) {
	yield(1)
	yield(2)
}

// Swallows recovers a panic that came out of the loop body.
func Swallows(yield func(int) bool) {
	defer func() { recover() }()
	yield(1)
}

var saved func(int) bool

// Stashes keeps yield and calls it after the loop is over.
func Stashes(yield func(int) bool) {
	saved = yield
	yield(1)
}

func main() {
	switch os.Args[1] {
	case "careless":
		for n := range Careless {
			fmt.Println("loop: got", n)
			break
		}
	case "swallows":
		for range Swallows {
			panic("cannot pack this order")
		}
	case "stashes":
		for n := range Stashes {
			fmt.Println("loop: got", n)
		}
		fmt.Println("main: the loop is over")
		saved(2)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build misuse.go'
(cd "$dir" && go build misuse.go) || exit 1

for misuse in careless swallows stashes; do
	say "./misuse $misuse"
	(cd "$dir" && ./misuse "$misuse" 2>stderr.txt)
	status=$?
	grep 'panic:' "$dir/stderr.txt" | sed 's/^[[:space:]]*//'
	echo "exit status $status"
done
