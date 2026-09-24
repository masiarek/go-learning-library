#!/usr/bin/env bash
# unsafe.Slice builds a slice from a pointer and a length; handing it a slice
# is refused. unsafe.SliceData is the pointer it wants.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/view.go" <<'GO'
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	packet := []byte("HELLO")
	head := unsafe.Slice(packet, 2)
	fmt.Println(head)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build view.go'
(cd "$dir" && go build view.go) 2>&1
echo "exit status $?"
