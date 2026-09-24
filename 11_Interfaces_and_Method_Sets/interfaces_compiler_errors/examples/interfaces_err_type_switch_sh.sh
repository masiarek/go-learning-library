#!/usr/bin/env bash
# Three type-switch mistakes in one file: a case type the switched value can
# never have, the same type in two cases, and a bound variable that no case
# uses.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/classify.go" <<'GO'
package main

import "fmt"

type Order struct{ ID int }

func kind(s fmt.Stringer) string {
	switch s.(type) {
	case Order:
		return "order"
	}
	return "other"
}

func size(v any) string {
	switch v.(type) {
	case int:
		return "int"
	case string:
		return "string"
	case int:
		return "int again"
	}
	return "other"
}

func main() {
	var v any = 3
	switch x := v.(type) {
	case int:
		fmt.Println("an int")
	case string:
		fmt.Println("a string")
	}
	fmt.Println(kind(nil), size(v))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build classify.go'
(cd "$dir" && go build classify.go) 2>&1
echo "exit status $?"
