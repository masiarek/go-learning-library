#!/usr/bin/env bash
# vet's stdversion analyzer: a module whose go.mod says go 1.22 uses iter.Seq
# and slices.Collect as types and calls only, with no range over a function.
# The compiler accepts it, because importing a newer package is not a language
# change; vet reports each symbol newer than the module's Go version.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

import (
	"fmt"
	"iter"
	"slices"
)

// Doubled returns an iterator over twice each reading.
func Doubled(readings []int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for _, r := range readings {
			if !yield(2 * r) {
				return
			}
		}
	}
}

func main() {
	fmt.Println(slices.Collect(Doubled([]int{21, 19, 23})))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1
say 'go mod edit -go=1.22'
go mod edit -go=1.22
say 'go build .'
go build -o /dev/null . 2>&1
echo "exit status $?"
say 'go vet .'
go vet . 2>&1
echo "exit status $?"

say 'go mod edit -go=1.23'
go mod edit -go=1.23
say 'go vet .'
go vet . 2>&1
echo "exit status $?"
