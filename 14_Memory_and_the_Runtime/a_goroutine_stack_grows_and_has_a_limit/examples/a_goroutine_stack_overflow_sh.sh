#!/usr/bin/env bash
# A goroutine that grows its stack past the limit is not a panic that can be
# recovered: the runtime prints "fatal error: stack overflow" and the process
# exits with status 2. The program lowers the limit to 1 MiB with
# debug.SetMaxStack so that the overflow comes quickly. The stderr also
# carries stack addresses and a goroutine trace with a temporary path, so
# this script keeps only the two lines that name the failure.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/overflow.go" <<'GO'
package main

import (
	"fmt"
	"runtime/debug"
)

// dive never reaches a base case; each call adds a frame.
func dive(depth int) int {
	return dive(depth+1) + 1
}

func main() {
	debug.SetMaxStack(1 << 20)
	fmt.Println("limit set to 1 MiB, recursing without end")
	fmt.Println(dive(0))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build overflow.go'
(cd "$dir" && go build overflow.go) || exit 1

say './overflow'
(cd "$dir" && ./overflow 2>stderr.txt)
status=$?
grep -E '^runtime: goroutine stack exceeds|^fatal error: stack overflow' "$dir/stderr.txt"
echo "exit status $status"
