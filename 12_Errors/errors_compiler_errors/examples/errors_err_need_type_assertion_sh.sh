#!/usr/bin/env bash
# Assigning an error to a variable of the concrete type. An interface value
# does not convert down by itself: the compiler asks for a type assertion,
# and errors.As is the assertion that also searches the chain.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/need_assertion.go" <<'GO'
package main

import "fmt"

type NotFoundError struct{ ID int }

func (e *NotFoundError) Error() string { return fmt.Sprintf("order %d not found", e.ID) }

func findOrder(id int) error { return &NotFoundError{id} }

func main() {
	err := findOrder(7)
	var nf *NotFoundError = err
	fmt.Println(nf.ID)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build need_assertion.go'
(cd "$dir" && go build need_assertion.go) 2>&1
echo "exit status $?"
