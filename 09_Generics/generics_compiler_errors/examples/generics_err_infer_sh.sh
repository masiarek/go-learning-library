#!/usr/bin/env bash
# "cannot infer T": inference reads a call's arguments and nothing else. A type
# parameter that appears only in the result, or one whose argument is nil, has
# nothing to be inferred from -- and once an argument has fixed T, a later
# argument of another type does not widen it.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/infer.go" <<'GO'
package main

import "fmt"

func Zero[T any]() T {
	var zero T
	return zero
}

func Map[T, U any](in []T, f func(T) U) []U {
	out := make([]U, 0, len(in))
	for _, v := range in {
		out = append(out, f(v))
	}
	return out
}

func Index[T comparable](values []T, want T) int { return -1 }

func main() {
	var count int = Zero()
	names := []string{"pear"}
	fmt.Println(count, Map(names, nil))
	fmt.Println(Index([]any{[]int{1}}, []int{1}))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build infer.go'
(cd "$dir" && go build infer.go) 2>&1
echo "exit status $?"
