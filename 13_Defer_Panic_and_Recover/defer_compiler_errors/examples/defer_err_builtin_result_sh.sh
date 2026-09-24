#!/usr/bin/env bash
# A built-in function whose result would be thrown away cannot be deferred:
# append returns the new slice, and a deferred call has nowhere to put it.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/builtin_result.go" <<'GO'
package main

import "fmt"

func main() {
	audit := []string{"started"}
	defer append(audit, "finished")
	defer len(audit)
	fmt.Println(audit)
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go build builtin_result.go'
go build builtin_result.go 2>&1
echo "exit status $?"
