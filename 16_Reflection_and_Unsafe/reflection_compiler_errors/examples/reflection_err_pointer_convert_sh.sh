#!/usr/bin/env bash
# A *int cannot be converted to a *float64: the pointer types are unrelated,
# and the compiler refuses. Only unsafe.Pointer stands between them.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/bits.go" <<'GO'
package main

import "fmt"

func main() {
	x := 1
	asFloat := (*float64)(&x)
	fmt.Println(*asFloat)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build bits.go'
(cd "$dir" && go build bits.go) 2>&1
echo "exit status $?"
