#!/usr/bin/env bash
# The stdmethods analyzer knows the signatures the errors package looks for.
# An Unwrap, Is or As with the wrong signature is a method the errors package
# never calls: the program shows errors.Unwrap ignoring it. The same names on
# a type that is not an error are left alone.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >wrong_signatures.go <<'GO'
package main

import (
	"errors"
	"fmt"
)

var ErrTimeout = errors.New("timeout")

type QueryError struct {
	Query string
	Err   error
}

func (e *QueryError) Error() string        { return e.Query + ": " + e.Err.Error() }
func (e *QueryError) Unwrap() *QueryError  { return nil }
func (e *QueryError) Is(target any) bool   { return target == ErrTimeout }
func (e *QueryError) As(target error) bool { return false }

// Catalogue is not an error: its Is and Unwrap mean something else, and the
// analyzer leaves them alone.
type Catalogue map[string]bool

func (c Catalogue) Is(sku any) bool  { return c[sku.(string)] }
func (c Catalogue) Unwrap() []string { return nil }

func main() {
	fmt.Println("catalogue has lamp:", Catalogue{"lamp": true}.Is("lamp"))
	err := &QueryError{"select 1", ErrTimeout}
	fmt.Println("errors.Unwrap(err):", errors.Unwrap(err))
	fmt.Println("errors.Is(err, ErrTimeout):", errors.Is(err, ErrTimeout))
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
