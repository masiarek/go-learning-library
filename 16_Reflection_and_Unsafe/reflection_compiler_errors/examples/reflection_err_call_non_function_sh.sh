#!/usr/bin/env bash
# Value.Method(i) returns a reflect.Value, not a Go function: it cannot be
# called with parentheses. Value.Call is the call.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/method.go" <<'GO'
package main

import (
	"fmt"
	"reflect"
)

type Invoice struct{ Amount float64 }

func (inv Invoice) Total() float64 { return inv.Amount * 1.2 }

func main() {
	inv := Invoice{Amount: 100}
	total := reflect.ValueOf(inv).MethodByName("Total")()
	fmt.Println(total)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build method.go'
(cd "$dir" && go build method.go) 2>&1
echo "exit status $?"
