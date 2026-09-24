#!/usr/bin/env bash
# An array's length is part of its type, so it must be a constant: not a
# variable, and not negative.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/lengths.go" <<'GO'
package main

import "fmt"

func main() {
	slots := 4
	var perTable [slots]int
	var negative [-1]int
	fmt.Println(slots, perTable, negative)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build lengths.go'
(cd "$dir" && go build lengths.go) 2>&1
echo "exit status $?"
