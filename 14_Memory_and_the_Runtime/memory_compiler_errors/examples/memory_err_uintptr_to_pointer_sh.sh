#!/usr/bin/env bash
# A uintptr is an integer, not a pointer: the compiler will not convert it
# to *T directly. The only route is through unsafe.Pointer, and go vet's
# unsafeptr check has an opinion about that route too.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/integer_pointer.go" <<'GO'
package main

import (
	"fmt"
	"unsafe"
)

type Order struct{ Qty int }

func main() {
	o := Order{Qty: 2}
	addr := uintptr(unsafe.Pointer(&o))
	back := (*Order)(addr)
	fmt.Println(back.Qty)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build integer_pointer.go'
(cd "$dir" && go build integer_pointer.go) 2>&1
echo "exit status $?"
