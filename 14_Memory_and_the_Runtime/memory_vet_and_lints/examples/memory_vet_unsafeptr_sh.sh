#!/usr/bin/env bash
# go vet's unsafeptr analyzer: a uintptr that was a pointer is an integer
# the collector does not know about, so converting it back is flagged. The
# good file does the arithmetic in one expression, which is a pattern the
# unsafe.Pointer rules allow, and with unsafe.Add.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
mkdir "$dir/bad" "$dir/good"

cat >"$dir/bad/second_field.go" <<'GO'
package main

import (
	"fmt"
	"unsafe"
)

type Order struct {
	ID  int64
	Qty int64
}

func main() {
	o := Order{ID: 1, Qty: 2}
	addr := uintptr(unsafe.Pointer(&o)) + unsafe.Offsetof(o.Qty)
	qty := (*int64)(unsafe.Pointer(addr))
	fmt.Println(*qty)
}
GO

cat >"$dir/good/second_field.go" <<'GO'
package main

import (
	"fmt"
	"unsafe"
)

type Order struct {
	ID  int64
	Qty int64
}

func main() {
	o := Order{ID: 1, Qty: 2}
	qty := (*int64)(unsafe.Pointer(uintptr(unsafe.Pointer(&o)) + unsafe.Offsetof(o.Qty)))
	viaAdd := (*int64)(unsafe.Add(unsafe.Pointer(&o), unsafe.Offsetof(o.Qty)))
	fmt.Println(*qty, *viaAdd)
}
GO

say() { printf '$ %s\n' "$*"; }

for pkg in bad good; do
	say "cd $pkg && go mod init example && go vet ."
	(cd "$dir/$pkg" && go mod init example >/dev/null 2>&1 && go vet . 2>&1)
	echo "exit status $?"
done
