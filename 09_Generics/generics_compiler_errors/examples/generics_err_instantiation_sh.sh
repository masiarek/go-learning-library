#!/usr/bin/env bash
# A generic function or type is not a value or a type until it is instantiated.
# Assigning Map to a variable, declaring a Stack with no type argument, and
# giving Pair one argument instead of two are each refused.
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

func Map[T, U any](in []T, f func(T) U) []U { return nil }

func main() {
	toLabel := Map
	var invoices Stack
	var entry Pair[string]
	_, _, _ = toLabel, invoices, entry
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build uninstantiated.go'
(cd "$dir" && go build uninstantiated.go) 2>&1
echo "exit status $?"
