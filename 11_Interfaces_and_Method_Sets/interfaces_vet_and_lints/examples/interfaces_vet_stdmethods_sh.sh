#!/usr/bin/env bash
# stdmethods: methods whose names the standard library gives a meaning, with
# the wrong signature. Invoice gets four of them wrong. vet reports the two
# on its list (WriteTo, MarshalJSON) and says nothing about String() int and
# Error() int -- those the compiler reports, but only where the value is
# used as a Stringer or an error.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

import (
	"fmt"
	"io"
)

type Invoice struct{ ID int }

func (i Invoice) String() int               { return i.ID }
func (i Invoice) Error() int                { return i.ID }
func (i Invoice) WriteTo(w io.Writer) error { return nil }
func (i Invoice) MarshalJSON() []byte       { return nil }

func main() { fmt.Println(Invoice{7}.ID) }
GO

cat >use.go <<'GO'
package main

import "fmt"

var _ fmt.Stringer = Invoice{}
var _ error = Invoice{}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet main.go'
go vet main.go 2>&1
echo "exit status $?"

say 'go build main.go use.go'
go build main.go use.go 2>&1
echo "exit status $?"
