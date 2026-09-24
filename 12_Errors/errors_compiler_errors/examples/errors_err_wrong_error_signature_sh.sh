#!/usr/bin/env bash
# A type whose Error method returns an error instead of a string does not
# implement error, and the compiler says exactly which signature it wanted.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/wrong_signature.go" <<'GO'
package main

import "fmt"

type QuotaError struct{ Limit int }

func (e QuotaError) Error() error { return fmt.Errorf("quota of %d exceeded", e.Limit) }

func reserve(n int) error {
	if n > 10 {
		return QuotaError{10}
	}
	return nil
}

func main() { fmt.Println(reserve(11)) }
GO

say() { printf '$ %s\n' "$*"; }

say 'go build wrong_signature.go'
(cd "$dir" && go build wrong_signature.go) 2>&1
echo "exit status $?"
