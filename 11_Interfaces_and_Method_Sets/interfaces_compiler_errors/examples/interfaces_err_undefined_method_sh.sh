#!/usr/bin/env bash
# The static type of a variable of interface type is the interface, and only
# its methods can be called -- whatever the dynamic value can also do.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/logger.go" <<'GO'
package main

import "fmt"

type Logger interface{ Log(line string) }

type Console struct{ lines int }

func (c *Console) Log(line string) { c.lines++; fmt.Println(line) }
func (c *Console) Flush()          { fmt.Println("flushed", c.lines, "lines") }

func main() {
	var l Logger = &Console{}
	l.Log("order 7 shipped")
	l.Flush()
}
GO

cat >"$dir/logger_asserted.go" <<'GO'
package main

import "fmt"

type Logger interface{ Log(line string) }

type Console struct{ lines int }

func (c *Console) Log(line string) { c.lines++; fmt.Println(line) }
func (c *Console) Flush()          { fmt.Println("flushed", c.lines, "lines") }

func main() {
	var l Logger = &Console{}
	l.Log("order 7 shipped")
	if f, ok := l.(interface{ Flush() }); ok { // ask the dynamic value, at run time
		f.Flush()
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build logger.go'
(cd "$dir" && go build logger.go) 2>&1
echo "exit status $?"

say 'go run logger_asserted.go'
(cd "$dir" && go run logger_asserted.go) 2>&1
echo "exit status $?"
