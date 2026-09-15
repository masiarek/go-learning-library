#!/usr/bin/env bash
# `go` is a statement, not an expression, so there is nothing to assign: the
# line a reader coming from Rust's thread::spawn or Java's submit writes first
# does not compile. The script prints the compiler's message and its status.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/total.go" <<'GO'
package main

import "fmt"

func sum(prices []int) int {
	total := 0
	for _, p := range prices {
		total += p
	}
	return total
}

func main() {
	total := go sum([]int{1999, 450, 1200})
	fmt.Println(total)
}
GO

say() { printf '$ %s\n' "$*"; }

cd "$dir" || exit 1
say 'go build total.go'
go build total.go 2>&1
echo "exit status $?"
