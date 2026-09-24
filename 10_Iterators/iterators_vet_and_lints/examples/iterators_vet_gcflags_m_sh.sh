#!/usr/bin/env bash
# go build -gcflags=-m on a range over a function: the loop body is compiled
# to a function named main-range1, and the compiler reports inlining both the
# iterator and that body into main. With -l, inlining off, the body is
# reported as a func literal that does not escape.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/total.go" <<'GO'
package main

import "fmt"

func Readings(yield func(int) bool) {
	for _, r := range []int{21, 19, 23} {
		if !yield(r) {
			return
		}
	}
}

func main() {
	total := 0
	for r := range Readings {
		total += r
	}
	fmt.Println(total)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build -gcflags=-m total.go'
(cd "$dir" && go build -gcflags=-m -o /dev/null total.go) 2>&1 | grep -v '^#'
echo "exit status $?"

say 'go build -gcflags="-m -l" total.go'
(cd "$dir" && go build -gcflags="-m -l" -o /dev/null total.go) 2>&1 | grep -v '^#'
echo "exit status $?"
