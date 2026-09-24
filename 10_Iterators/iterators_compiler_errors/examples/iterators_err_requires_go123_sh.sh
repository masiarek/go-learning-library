#!/usr/bin/env bash
# A module whose go.mod says go 1.22. The toolchain is 1.25, but the language
# version comes from go.mod, and range over a function is a Go 1.23 feature.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cd "$dir" || exit 1

cat >main.go <<'GO'
package main

import "fmt"

func Readings(yield func(int) bool) {
	_ = yield(21)
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
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

say 'go mod edit -go=1.23'
go mod edit -go=1.23
say 'go build .'
go build -o /dev/null . 2>&1
echo "exit status $?"
