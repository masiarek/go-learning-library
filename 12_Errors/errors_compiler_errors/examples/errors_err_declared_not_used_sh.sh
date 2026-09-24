#!/usr/bin/env bash
# An error result that is received and never looked at. The compiler refuses:
# err is declared and not used, and there is no warning level to lower it to.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/unused_err.go" <<'GO'
package main

import "os"

func main() {
	orders, err := os.Open("orders.csv")
	orders.Close()
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build unused_err.go'
(cd "$dir" && go build unused_err.go) 2>&1
echo "exit status $?"
