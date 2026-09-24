#!/usr/bin/env bash
# The unusedresult analyzer: fmt.Errorf, errors.New and Error() have no side
# effects, so a call whose result is dropped did nothing. The usual story is
# an Errorf that was meant to be returned.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >dropped_results.go <<'GO'
package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("order not found")

func load(id int) error {
	if id > 100 {
		fmt.Errorf("load order %d: %w", id, ErrNotFound)
	}
	return nil
}

func main() {
	errors.New("never returned")
	ErrNotFound.Error()
	fmt.Println("load(101) returned:", load(101))
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
