#!/usr/bin/env bash
# Comparing an error with its text. A string is not an error, so errors.Is
# refuses it; and err.Error without the parentheses is a method value, not
# a string, so == refuses that too.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/text_is_not_an_error.go" <<'GO'
package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("order not found")

func main() {
	err := fmt.Errorf("load order 7: %w", ErrNotFound)
	if errors.Is(err, "order not found") {
		fmt.Println("not found")
	}
	if err.Error == "order not found" {
		fmt.Println("not found")
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build text_is_not_an_error.go'
(cd "$dir" && go build text_is_not_an_error.go) 2>&1
echo "exit status $?"
