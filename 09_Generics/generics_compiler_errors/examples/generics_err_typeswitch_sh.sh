#!/usr/bin/env bash
# A value of type parameter type is not an interface value: no type switch and
# no type assertion on it directly. Converting it to any first is allowed, and
# the fixed version prints what the switch found.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/typeswitch.go" <<'GO'
package main

func Kind[T any](v T) string {
	switch v.(type) {
	case int:
		return "int"
	}
	if _, ok := v.(string); ok {
		return "string"
	}
	return "other"
}

func main() { _ = Kind(1) }
GO

cat >"$dir/typeswitch_fixed.go" <<'GO'
package main

import "fmt"

func Kind[T any](v T) string {
	switch any(v).(type) {
	case int:
		return "int"
	case string:
		return "string"
	}
	return "other"
}

func main() { fmt.Println(Kind(1), Kind("pear"), Kind(2.5)) }
GO

say() { printf '$ %s\n' "$*"; }

say 'go build typeswitch.go'
(cd "$dir" && go build typeswitch.go) 2>&1
echo "exit status $?"

say 'go run typeswitch_fixed.go'
(cd "$dir" && go run typeswitch_fixed.go) 2>&1
echo "exit status $?"
