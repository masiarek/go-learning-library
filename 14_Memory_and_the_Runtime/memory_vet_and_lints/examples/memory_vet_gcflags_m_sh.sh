#!/usr/bin/env bash
# -gcflags=-m is not a linter, but it is the tool that says where each value
# went and which calls were inlined. This file is built to show every kind
# of line the flag prints, so the page can say what each wording means.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/registry.go" <<'GO'
package main

type Order struct {
	ID    int
	Notes []string
}

var registry []*Order

// register keeps o: the parameter leaks to the heap.
func register(o *Order) {
	registry = append(registry, o)
}

// idOf reads through o and keeps nothing: o does not escape.
func idOf(o *Order) int {
	return o.ID
}

// notesOf returns what o points at, not o itself: the content leaks.
func notesOf(o *Order) []string {
	return o.Notes
}

// double is small enough to inline.
func double(qty int) int {
	return qty * 2
}

func main() {
	o := &Order{ID: 1, Notes: []string{"rush"}}
	register(o)
	if idOf(o)+len(notesOf(o))+double(2) == 0 {
		panic("nothing registered")
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build -gcflags=-m registry.go 2>&1 | grep -v "^#"'
(cd "$dir" && go build -gcflags=-m registry.go 2>&1) | grep -v '^#'
echo "exit status ${PIPESTATUS[0]}"
