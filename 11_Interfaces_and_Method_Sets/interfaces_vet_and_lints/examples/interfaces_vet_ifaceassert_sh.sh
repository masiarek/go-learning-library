#!/usr/bin/env bash
# ifaceassert: an assertion from one interface to another that no type can
# ever satisfy, because the two interfaces want the same method name with
# different signatures. It compiles; go vet refuses it.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

import "fmt"

// Closer is what the connection pool returns.
type Closer interface{ Close() error }

// Shutdowner is an older interface with a Close that returns nothing.
type Shutdowner interface{ Close() }

func shutdown(c Closer) {
	if s, ok := c.(Shutdowner); ok { // no type has both Close() error and Close()
		s.Close()
		return
	}
	fmt.Println("not a Shutdowner")
}

func main() { shutdown(nil) }
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go build ./...'
go build ./... 2>&1
echo "exit status $?"

say 'go vet ./...'
go vet ./... 2>&1
echo "exit status $?"
