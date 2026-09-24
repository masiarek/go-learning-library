#!/usr/bin/env bash
# An import that nothing uses and a local variable that nothing reads are
# both compile errors in Go, not warnings, and the compiler reports every one
# it finds in one run.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

cat >main.go <<'GO'
package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	count := 3
	label := strings.ToUpper("orders")
	fmt.Println(label)
}
GO

say 'go build -o report .'
go build -o report . 2>&1
echo "exit status $?"
