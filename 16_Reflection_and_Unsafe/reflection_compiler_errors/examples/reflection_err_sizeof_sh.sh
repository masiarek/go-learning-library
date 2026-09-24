#!/usr/bin/env bash
# unsafe.Sizeof takes an expression that has a type: not an untyped nil, not
# a type name, and not a call that returns nothing.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/sizes.go" <<'GO'
package main

import (
	"fmt"
	"unsafe"
)

func audit() {}

func main() {
	fmt.Println(unsafe.Sizeof(nil))
	fmt.Println(unsafe.Sizeof(int64))
	fmt.Println(unsafe.Sizeof(audit()))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build sizes.go'
(cd "$dir" && go build sizes.go) 2>&1
echo "exit status $?"
