#!/usr/bin/env bash
# Counter has Increment on a pointer receiver only. Four lines that look
# like they should work are compile errors: assigning a Counter value to an
# interface that needs Increment, and calling Increment on a map element, on
# a value held in an interface, and on a composite literal -- none of which
# is addressable. The same four lines with an address in hand compile.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/not_addressable.go" <<'GO'
package main

type Counter struct{ orders int }

func (c Counter) Value() int  { return c.orders }
func (c *Counter) Increment() { c.orders++ }

type Incrementer interface{ Increment() }

func main() {
	var c Counter
	var inc Incrementer = c // Counter's method set has no Increment
	byQueue := map[string]Counter{"web": {}}
	byQueue["web"].Increment() // a map element is not addressable
	var boxed any = c
	boxed.(Counter).Increment() // nor is a value inside an interface
	Counter{}.Increment()       // nor is a composite literal
	_ = inc
}
GO

cat >"$dir/addressable.go" <<'GO'
package main

import "fmt"

type Counter struct{ orders int }

func (c Counter) Value() int  { return c.orders }
func (c *Counter) Increment() { c.orders++ }

type Incrementer interface{ Increment() }

func main() {
	var c Counter
	var inc Incrementer = &c // *Counter has Increment
	byQueue := map[string]*Counter{"web": {}}
	byQueue["web"].Increment() // the map holds pointers
	var boxed any = &c
	boxed.(*Counter).Increment() // the interface holds a pointer
	(&Counter{}).Increment()     // an explicit address
	inc.Increment()
	fmt.Println(c.Value(), byQueue["web"].Value())
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build not_addressable.go'
(cd "$dir" && go build not_addressable.go) 2>&1
echo "exit status $?"

say 'go build addressable.go'
(cd "$dir" && go build addressable.go) 2>&1
echo "exit status $?"
