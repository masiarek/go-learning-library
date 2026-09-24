#!/usr/bin/env bash
# The errorsas analyzer reads the static type of errors.As's second argument:
# a nil pointer variable, a struct value, a pointer to a type whose methods
# are on the pointer, and a pointer to an error interface are each reported.
# The first of them also panics at run time, which the script shows.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >as_targets.go <<'GO'
package main

import (
	"errors"
	"fmt"
)

type NotFoundError struct{ ID int }

func (e *NotFoundError) Error() string { return fmt.Sprintf("order %d not found", e.ID) }

func main() {
	err := fmt.Errorf("load: %w", &NotFoundError{7})
	var nf *NotFoundError
	fmt.Println(errors.As(err, nf))
	fmt.Println(errors.As(err, NotFoundError{}))
	var value NotFoundError
	fmt.Println(errors.As(err, &value))
	var target error
	fmt.Println(errors.As(err, &target))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet .'
go vet . 2>&1
echo "exit status $?"

say 'go build -o as_targets . && ./as_targets'
go build -o as_targets . || exit 1
./as_targets 2>stderr.txt
status=$?
grep '^panic:' stderr.txt
echo "exit status $status"
