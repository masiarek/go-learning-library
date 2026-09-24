#!/usr/bin/env bash
# Two assertions the compiler can already rule out: asserting a fmt.Stringer
# to a type that has no String method, and asserting on a value that is not
# an interface at all. Neither reaches the run-time check.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/assertions.go" <<'GO'
package main

import "fmt"

type Order struct{ ID int }

func main() {
	var s fmt.Stringer
	if o, ok := s.(Order); ok {
		fmt.Println(o.ID)
	}
	quantity := 3
	if n, ok := quantity.(int); ok {
		fmt.Println(n)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build assertions.go'
(cd "$dir" && go build assertions.go) 2>&1
echo "exit status $?"
