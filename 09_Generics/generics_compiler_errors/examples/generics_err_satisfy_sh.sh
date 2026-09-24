#!/usr/bin/env bash
# "does not satisfy": the type argument is outside the constraint's type set.
# Three ways in: a union term without ~, a slice given to comparable, and a
# type that lacks the constraint's method.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/satisfy.go" <<'GO'
package main

import "fmt"

type Exact interface{ int | float64 }

type Celsius float64

func Double[T Exact](v T) T { return v * 2 }

func Index[T comparable](values []T, want T) int { return -1 }

type Stringer interface{ String() string }

func Show[T Stringer](v T) string { return v.String() }

func main() {
	fmt.Println(Double(Celsius(21)))
	fmt.Println(Index([][]int{{1}}, []int{1}))
	fmt.Println(Show(42))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build satisfy.go'
(cd "$dir" && go build satisfy.go) 2>&1
echo "exit status $?"
