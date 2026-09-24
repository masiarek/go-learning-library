#!/usr/bin/env bash
# Three places where inference has nothing to read: a type parameter that
# appears only in the result, a generic function assigned to a variable with
# no type, and a partial instantiation assigned the same way.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/from_result.go" <<'GO'
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

func main() {
	var count int = Zero()
	toLabel := Map
	fromInt := Map[int]
	fmt.Println(count, toLabel, fromInt)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build from_result.go'
(cd "$dir" && go build from_result.go) 2>&1
echo "exit status $?"
