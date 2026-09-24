#!/usr/bin/env bash
# The compiler reports its inlining decisions under -gcflags=-m: which
# functions it can inline and which calls it inlined. The reason a function is
# NOT inlined only appears at -m=2. This script builds one file with six
# functions and prints both views. The cost numbers in the -m=2 reasons are the
# compiler's own estimate and can move between compiler versions, so the
# script blanks them; demo/inline_full.sh prints them.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

// A few nodes: well under the budget.
func add(a, b int) int { return a + b }

// A for loop is no obstacle since Go 1.16.
func sumTo(n int) int {
	total := 0
	for i := 1; i <= n; i++ {
		total += i
	}
	return total
}

// defer and recover each rule a function out.
func safeDivide(a, b int) (quotient int, ok bool) {
	defer func() {
		if recover() != nil {
			ok = false
		}
	}()
	return a / b, true
}

// Too many nodes for the budget of 80.
func big(x int) int {
	a := x * 3
	b := a + 7
	c := b ^ 0x55
	d := c << 2
	e := d - x
	f := e * e
	g := f % 1000
	h := g + a
	i := h ^ b
	j := i + c
	k := j * d
	l := k - e
	m := l + f
	n := m ^ g
	o := n + h
	p := o * i
	return p - j
}

// Small enough, but told not to.
//
//go:noinline
func keepOut(a, b int) int { return a * b }

func main() {
	println(add(2, 3), sumTo(10), big(4), keepOut(6, 7))
	println(safeDivide(7, 0))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go build -gcflags=-m . 2>&1 | grep inlin'
go build -gcflags=-m . 2>&1 | grep inlin
echo "exit status ${PIPESTATUS[0]}"

say "go build -gcflags=-m . 2>&1 | grep -c 'cannot inline'"
go build -gcflags=-m . 2>&1 | grep -c 'cannot inline'

say "go build -gcflags=-m=2 . 2>&1 | grep 'cannot inline'"
go build -gcflags=-m=2 . 2>&1 | grep 'cannot inline' | sed -E 's/cost [0-9]+ exceeds/cost (a number) exceeds/'
echo "exit status ${PIPESTATUS[0]}"
