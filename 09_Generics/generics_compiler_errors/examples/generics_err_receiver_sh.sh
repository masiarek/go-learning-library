#!/usr/bin/env bash
# The names in a receiver's brackets declare type parameters; they never pick
# an instantiation. Stack[int] declares a parameter called int, which shadows
# the predeclared int inside the method.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/receiver.go" <<'GO'
package main

type Stack[T any] struct{ items []T }

func (s *Stack[int]) Sum() int {
	total := 0
	for _, v := range s.items {
		total += v
	}
	return total
}

func main() {}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build receiver.go'
(cd "$dir" && go build receiver.go) 2>&1
echo "exit status $?"
