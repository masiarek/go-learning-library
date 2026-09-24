#!/usr/bin/env bash
# Three things that look like a deferred call and are not: a method value
# without its parentheses, a call wrapped in parentheses, and a conversion.
# The compiler names each one.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/not_a_call.go" <<'GO'
package main

import "os"

type Cents int

func main() {
	f, err := os.Open("orders.csv")
	if err != nil {
		return
	}
	defer f.Close
	defer (f.Close())
	total := 1999
	defer Cents(total)
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go build not_a_call.go'
go build not_a_call.go 2>&1
echo "exit status $?"
