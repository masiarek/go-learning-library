#!/usr/bin/env bash
# The stdversion analyzer: a call to a standard-library function newer than
# the go line in go.mod is reported by vet and accepted by the compiler,
# which checks the language version and not the API. The analyzer is silent
# for a go line before 1.21, when that line was not yet a promise.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

printf 'module example\n\ngo 1.21\n' >go.mod
cat >main.go <<'GO'
package main

import (
	"fmt"
	"slices"
)

func main() {
	lines := slices.Concat([]string{"invoice 1042"}, []string{"3 lines"})
	fmt.Println(lines)
}
GO

say 'cat go.mod'
cat go.mod
say 'go vet .   # slices.Concat is new in Go 1.22'
go vet . 2>&1
echo "exit status $?"
say 'go build -o report . && ./report'
go build -o report . 2>&1 && ./report
echo "exit status $?"

printf 'module example\n\ngo 1.20\n' >go.mod
cat >main.go <<'GO'
package main

import (
	"fmt"
	"slices"
)

func main() {
	amounts := []int{30, 10, 20}
	slices.Sort(amounts)
	fmt.Println(amounts)
}
GO
say 'cat go.mod'
cat go.mod
say 'go vet .   # package slices is new in Go 1.21, but the go line is before 1.21'
go vet . 2>&1
echo "exit status $?"
say 'go build -o report . && ./report'
go build -o report . 2>&1 && ./report
echo "exit status $?"

cat >main.go <<'GO'
package main

import "fmt"

func main() {
	for i := range 3 {
		fmt.Println("line", i)
	}
}
GO
say 'go build -o report .   # range over an int is Go 1.22 language, and the go line is 1.20'
go build -o report . 2>&1
echo "exit status $?"

printf 'module example\n\ngo 1.22\n' >go.mod
say 'cat go.mod'
cat go.mod
say 'go vet . && go build -o report . && ./report'
go vet . 2>&1 && go build -o report . 2>&1 && ./report
echo "exit status $?"
