#!/usr/bin/env bash
# A map element is not addressable, so a field of a struct held in a map
# cannot be assigned in place.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/map_field.go" <<'GO'
package main

type Order struct{ Qty int }

func main() {
	orders := map[string]Order{"a-1": {Qty: 2}}
	orders["a-1"].Qty = 3
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build map_field.go'
(cd "$dir" && go build map_field.go) 2>&1
echo "exit status $?"
