#!/usr/bin/env bash
# unreachable: a statement after a panic can never run. panic is a
# terminating statement, like return, and vet flags what follows it.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/after_panic.go" <<'GO'
package main

import "fmt"

func mustPositive(quantity int) int {
	if quantity <= 0 {
		panic("quantity must be positive")
		fmt.Println("rejected quantity", quantity)
	}
	return quantity
}

func main() { fmt.Println(mustPositive(3)) }
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go vet after_panic.go'
go vet after_panic.go 2>&1
echo "exit status $?"
