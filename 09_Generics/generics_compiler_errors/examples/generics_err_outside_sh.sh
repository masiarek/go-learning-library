#!/usr/bin/env bash
# An interface that contains a union is a type set, usable only as a
# constraint: not as a parameter type, a variable's type, a slice's element
# type, or an embedded field.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/outside.go" <<'GO'
package main

type Number interface{ ~int | ~float64 }

type Reading struct {
	Number
}

func Describe(n Number) string { return "" }

func main() {
	var total Number
	var history []Number
	_, _ = total, history
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build outside.go'
(cd "$dir" && go build outside.go) 2>&1
echo "exit status $?"
