#!/usr/bin/env bash
# An unsafe.Pointer points at memory of no particular type, so it cannot be
# dereferenced, and an int is not an address, so it cannot become a Pointer.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/deref.go" <<'GO'
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	total := 42
	p := unsafe.Pointer(&total)
	fmt.Println(*p)
	q := unsafe.Pointer(total)
	fmt.Println(q)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build deref.go'
(cd "$dir" && go build deref.go) 2>&1
echo "exit status $?"
