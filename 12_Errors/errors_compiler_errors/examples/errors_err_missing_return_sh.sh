#!/usr/bin/env bash
# The failure path returns and the success path forgets to. A function with
# results must end in a terminating statement, and an if without else is not one.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/missing_return.go" <<'GO'
package main

import (
	"fmt"
	"os"
)

func size(name string) (int64, error) {
	info, err := os.Stat(name)
	if err != nil {
		return 0, fmt.Errorf("size of %s: %w", name, err)
	}
	fmt.Println("size:", info.Size())
}

func main() { fmt.Println(size("orders.csv")) }
GO

say() { printf '$ %s\n' "$*"; }

say 'go build missing_return.go'
(cd "$dir" && go build missing_return.go) 2>&1
echo "exit status $?"
