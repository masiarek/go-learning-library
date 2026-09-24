#!/usr/bin/env bash
# A generic type is not a type until it is instantiated. Stack alone, Pair with
# one argument, and Stack with two are each refused, and each differently. And
# a map keyed on a T that is not comparable is refused where it is declared.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/uninstantiated.go" <<'GO'
package main

type Stack[T any] struct{ items []T }

type Pair[K comparable, V any] struct {
	Key K
	Val V
}

type Bag[T any] map[T]int

func main() {
	var invoices Stack
	var entry Pair[string]
	var wide Stack[int, string]
	_, _, _ = invoices, entry, wide
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build uninstantiated.go'
(cd "$dir" && go build uninstantiated.go) 2>&1
echo "exit status $?"
