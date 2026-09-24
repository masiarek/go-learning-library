#!/usr/bin/env bash
# The deferred recover was written, its result was named, and then nothing
# looked at it. Go refuses an unused local variable, so the half-written
# handler does not compile.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/unused_recover.go" <<'GO'
package main

import "fmt"

func main() {
	defer func() {
		r := recover()
	}()
	fmt.Println("posting invoice 18")
	panic("invoice 18 has no customer")
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go build unused_recover.go'
go build unused_recover.go 2>&1
echo "exit status $?"
