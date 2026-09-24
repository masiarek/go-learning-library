#!/usr/bin/env bash
# Three things that have no address: a map element (the map may move it), a
# call's result, and a constant. The compiler refuses & on each of them.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/addresses.go" <<'GO'
package main

type Order struct{ Qty int }

func newest() Order { return Order{Qty: 1} }

func main() {
	orders := map[string]Order{"a-1": {Qty: 2}}
	fromMap := &orders["a-1"]
	fromCall := &newest()
	fromConst := &5
	_, _, _ = fromMap, fromCall, fromConst
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build addresses.go'
(cd "$dir" && go build addresses.go) 2>&1
echo "exit status $?"
