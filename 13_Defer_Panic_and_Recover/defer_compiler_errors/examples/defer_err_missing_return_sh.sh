#!/usr/bin/env bash
# A function with results must end in a terminating statement. A call to a
# helper that panics is not one, however certain the panic is; a panic
# statement is, so the second program needs no return after it and runs.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/missing.go" <<'GO'
package main

import "fmt"

func fail(msg string) { panic(msg) }

func customerOf(invoice int) string {
	if invoice == 18 {
		return "ACME"
	}
	fail("unknown invoice")
}

func main() { fmt.Println("customer of invoice 18:", customerOf(18)) }
GO

cat >"$dir/terminates.go" <<'GO'
package main

import "fmt"

func customerOf(invoice int) string {
	if invoice == 18 {
		return "ACME"
	}
	panic("unknown invoice")
}

func main() { fmt.Println("customer of invoice 18:", customerOf(18)) }
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go build missing.go'
go build missing.go 2>&1
echo "exit status $?"

say 'go build terminates.go'
go build terminates.go 2>&1
echo "exit status $?"
say './terminates'
./terminates
echo "exit status $?"
