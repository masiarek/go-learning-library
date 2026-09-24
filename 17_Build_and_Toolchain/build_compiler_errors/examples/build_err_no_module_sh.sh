#!/usr/bin/env bash
# go run main.go and go build main.go work in any directory: the go command
# treats the named files as a package of their own. go build . and
# go build ./... name packages, and packages live in modules, so without a
# go.mod they stop with a message that says what to run.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

cat >main.go <<'GO'
package main

import "fmt"

func main() { fmt.Println("orders: 3") }
GO

say 'go run main.go'
go run main.go 2>&1
echo "exit status $?"
say 'go build -o orders main.go'
go build -o orders main.go 2>&1
echo "exit status $?"
say 'go build -o orders .'
go build -o orders . 2>&1
echo "exit status $?"
say 'go build ./...'
go build ./... 2>&1
echo "exit status $?"
say 'go mod init example'
go mod init example 2>&1
say 'go build -o orders . && ./orders'
go build -o orders . 2>&1 && ./orders
echo "exit status $?"
