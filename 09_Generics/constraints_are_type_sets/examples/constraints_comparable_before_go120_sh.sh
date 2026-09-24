#!/usr/bin/env bash
# The same code, in a module whose go line says 1.19: the compiler applies the
# older rule, under which an interface type does not satisfy comparable. The
# go line changes what compiles, not which toolchain runs.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >go.mod <<'MOD'
module example

go 1.19
MOD

cat >main.go <<'GO'
package main

import "fmt"

func Index[T comparable](values []T, want T) int {
	for i, v := range values {
		if v == want {
			return i
		}
	}
	return -1
}

func main() {
	fmt.Println(Index([]any{1, "a", 2}, 2))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'cat go.mod'
cat go.mod

say 'go build .'
go build . 2>&1
echo "exit status $?"

say 'go mod edit -go=1.20 && go build . && ./example'
go mod edit -go=1.20 && go build . && ./example
echo "exit status $?"
