#!/usr/bin/env bash
# A reflect.Value is a struct that describes a value; it is not the value.
# Assigning one to an int, or comparing it with one, is a type error.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/value.go" <<'GO'
package main

import (
	"fmt"
	"reflect"
)

func main() {
	quantity := reflect.ValueOf(3)
	var n int = quantity
	fmt.Println(n, quantity == 3)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build value.go'
(cd "$dir" && go build value.go) 2>&1
echo "exit status $?"
