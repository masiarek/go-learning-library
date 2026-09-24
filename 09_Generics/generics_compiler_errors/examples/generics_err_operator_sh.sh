#!/usr/bin/env bash
# An operator is allowed on a T only if every type in T's set has it. Under any
# nothing is; under ~int | ~string, + is (both have it) and unary - is not.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/operators.go" <<'GO'
package main

func Larger[T any](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func Add[T any](a, b T) T { return a + b }

func Same[T any](a, b T) bool { return a == b }

func Concat[T ~int | ~string](a, b T) T { return a + b }

func Negate[T ~int | ~string](a T) T { return -a }

func main() {}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build operators.go'
(cd "$dir" && go build operators.go) 2>&1
echo "exit status $?"
