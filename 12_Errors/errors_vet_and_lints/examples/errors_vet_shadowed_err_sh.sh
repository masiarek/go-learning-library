#!/usr/bin/env bash
# A shadowed err: the := inside the if declares a new variable, the outer err
# stays nil, and the function returns nil after a failure. It compiles, go vet
# is silent, and go vet has no -shadow flag (the shadow analyzer is a separate
# tool in golang.org/x/tools, not part of the distribution).
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >shadowed_err.go <<'GO'
package main

import (
	"errors"
	"fmt"
)

var ErrNoCustomer = errors.New("customer is empty")

func check(customer string) error {
	if customer == "" {
		return ErrNoCustomer
	}
	return nil
}

// save means to return check's error, but the err inside the if is a new one.
func save(customer string, checked bool) error {
	var err error
	if !checked {
		err := check(customer)
		if err != nil {
			fmt.Println("save: check failed:", err)
		}
	}
	return err
}

func main() {
	fmt.Println("save returned:", save("", false))
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

say 'go vet -shadow .'
go vet -shadow . 2>&1
echo "exit status $?"
