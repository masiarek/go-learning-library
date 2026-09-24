#!/usr/bin/env bash
# GOGC and GOMEMLIMIT are read once, when the program starts. The program
# asks the runtime what it read: SetGCPercent(100) returns the value that was
# in force, and SetMemoryLimit(-1) returns the limit without changing it.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/settings.go" <<'GO'
package main

import (
	"fmt"
	"runtime/debug"
)

func main() {
	fmt.Println("GC percent at startup:", debug.SetGCPercent(100))
	fmt.Println("memory limit at startup:", debug.SetMemoryLimit(-1))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build settings.go'
(cd "$dir" && go build settings.go) || exit 1

say './settings'
(cd "$dir" && env -u GOGC -u GOMEMLIMIT ./settings)
say 'GOGC=50 ./settings'
(cd "$dir" && GOGC=50 ./settings)
say 'GOGC=off ./settings'
(cd "$dir" && GOGC=off ./settings)
say 'GOMEMLIMIT=64MiB ./settings'
(cd "$dir" && GOMEMLIMIT=64MiB ./settings)
say 'GOGC=off GOMEMLIMIT=1GiB ./settings'
(cd "$dir" && GOGC=off GOMEMLIMIT=1GiB ./settings)
echo "exit status $?"
