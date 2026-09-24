#!/usr/bin/env bash
# Ranging over a function whose one parameter is not a function. The
# compiler names the shape it wants, func(yield func(...) bool), and then what
# is wrong with the one it got.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/not_a_yield.go" <<'GO'
package main

import "fmt"

// Readings takes a count, so there is nothing for the loop to call.
func Readings(count int) {
	fmt.Println("readings:", count)
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build not_a_yield.go'
(cd "$dir" && go build not_a_yield.go) 2>&1
echo "exit status $?"
