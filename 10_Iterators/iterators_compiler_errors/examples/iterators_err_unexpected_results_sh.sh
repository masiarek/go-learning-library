#!/usr/bin/env bash
# An iterator that returns a value. The range statement has nowhere to put
# it, so an iterator function returns nothing.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/returns_bool.go" <<'GO'
package main

import "fmt"

// Readings hands back what yield returned, which a range cannot receive.
func Readings(yield func(int) bool) bool {
	return yield(21)
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build returns_bool.go'
(cd "$dir" && go build returns_bool.go) 2>&1
echo "exit status $?"
