#!/usr/bin/env bash
# Under the constraint any, a type parameter T admits every type -- so the
# compiler lets the function do only what every type can do. >, + and == are
# each refused, and each refusal is worded differently.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/under_any.go" <<'GO'
package main

func Max[T any](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func Sum[T any](values []T) T {
	var total T
	for _, v := range values {
		total = total + v
	}
	return total
}

func Contains[T any](values []T, want T) bool {
	for _, v := range values {
		if v == want {
			return true
		}
	}
	return false
}

func main() {}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build under_any.go'
(cd "$dir" && go build under_any.go) 2>&1
echo "exit status $?"
