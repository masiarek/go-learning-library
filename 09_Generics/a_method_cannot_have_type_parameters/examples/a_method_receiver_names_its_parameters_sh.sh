#!/usr/bin/env bash
# The identifiers in a receiver's brackets DECLARE the method's type parameters;
# they do not select an instantiation. Stack[int] here makes "int" a type
# parameter that shadows the predeclared int, so the constant 0 no longer fits.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/receiver_int.go" <<'GO'
package main

type Stack[T any] struct{ items []T }

// Sum was meant for Stack[int] only. Go has no such specialization: this
// declares a type parameter named int.
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

say 'go build receiver_int.go'
(cd "$dir" && go build receiver_int.go) 2>&1
echo "exit status $?"
