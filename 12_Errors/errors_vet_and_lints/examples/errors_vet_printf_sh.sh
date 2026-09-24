#!/usr/bin/env bash
# The printf analyzer on %w: Printf and Sprintf do not wrap, Errorf's %w wants
# an error operand, and a verb with no operand or an operand with no verb is a
# mismatch. Every one of these compiles, so the script also runs the program
# and shows what the bad calls print.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >wrap_verbs.go <<'GO'
package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("order not found")

func main() {
	fmt.Printf("printf : %w\n", ErrNotFound)
	fmt.Println(fmt.Sprintf("sprintf: %w", ErrNotFound))
	fmt.Println(fmt.Errorf("status %w", 503))
	fmt.Println(fmt.Errorf("count %d", ErrNotFound))
	fmt.Println(fmt.Errorf("load order: %w"))
	fmt.Println(fmt.Errorf("load order: %s", ErrNotFound, 7))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet .'
go vet . 2>&1
echo "exit status $?"

say 'go run .'
go run . 2>&1
echo "exit status $?"
