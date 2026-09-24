#!/usr/bin/env bash
# What can carry a method: a named type declared in this package that is
# not itself a pointer or an interface. A named pointer type, a built-in
# type and an interface type are refused, each with its own message.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/receivers.go" <<'GO'
package main

type Stack []int

func (s *Stack) Push(v int) { *s = append(*s, v) }

type StackRef *Stack

func (s StackRef) Len() int { return len(*s) }

func (n int) Cents() int { return n * 100 }

type Logger interface{ Log(line string) }

func (l Logger) Flush() {}

func main() {}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build receivers.go'
(cd "$dir" && go build receivers.go) 2>&1
echo "exit status $?"
