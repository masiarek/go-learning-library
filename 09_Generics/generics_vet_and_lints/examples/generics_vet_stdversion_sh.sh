#!/usr/bin/env bash
# stdversion: the generic helpers arrived in releases (cmp.Or and
# slices.Concat in 1.22) that a module's go line may be older than. The
# compiler builds the code anyway; vet is what says the line is a lie.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >go.mod <<'MOD'
module example

go 1.21
MOD

cat >main.go <<'GO'
package main

import (
	"cmp"
	"fmt"
	"slices"
)

func First[T comparable](values ...T) T { return cmp.Or(values...) }

func main() {
	fmt.Println(slices.Concat([]int{7}, []int{12}))
	fmt.Println(First("", "fallback"))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go vet .'
go vet . 2>&1
echo "exit status $?"

say 'go build .'
go build . 2>&1
echo "exit status $?"

say 'go mod edit -go=1.22 && go vet .'
go mod edit -go=1.22 && go vet . 2>&1
echo "exit status $?"
