#!/usr/bin/env bash
# unsafe.Offsetof takes a selector x.f naming a field of a struct. A plain
# variable is not a selector, and a field reached through an embedded
# pointer is not in the outer struct's memory at all.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/offsets.go" <<'GO'
package main

import (
	"fmt"
	"unsafe"
)

type Order struct {
	ID  int
	Qty int
}

// Line embeds a pointer to its Order, so Order's fields live elsewhere.
type Line struct {
	*Order
	Discount int
}

func main() {
	o := Order{ID: 1, Qty: 2}
	l := Line{Order: &o}
	fmt.Println(unsafe.Offsetof(o.Qty))    // fine: a field of o
	fmt.Println(unsafe.Offsetof(l.Discount)) // fine: a field of l
	fmt.Println(unsafe.Offsetof(o))
	fmt.Println(unsafe.Offsetof(l.Qty))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build offsets.go'
(cd "$dir" && go build offsets.go) 2>&1
echo "exit status $?"
