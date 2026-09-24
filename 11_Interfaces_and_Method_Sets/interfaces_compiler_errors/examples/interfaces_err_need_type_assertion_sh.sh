#!/usr/bin/env bash
# A value of interface type does not turn back into its dynamic type on its
# own: assigning an any to an int needs a type assertion.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/unbox.go" <<'GO'
package main

import "fmt"

func main() {
	settings := map[string]any{"retries": 3}
	var retries int = settings["retries"]
	fmt.Println(retries)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build unbox.go'
(cd "$dir" && go build unbox.go) 2>&1
echo "exit status $?"
