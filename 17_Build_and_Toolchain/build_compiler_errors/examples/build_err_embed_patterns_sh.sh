#!/usr/bin/env bash
# A //go:embed pattern is relative to the package directory and stays inside
# it: a file that does not exist, a path with .., an absolute path and an
# unterminated quoted pattern are each refused, before the compiler runs.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1
printf '1.4.2\n' >VERSION

attempt() {
	cat >main.go <<GO
package main

import (
	_ "embed"
	"fmt"
)

//go:embed $1
var version string

func main() { fmt.Println(version) }
GO
	say "go build -o report .   # //go:embed $1"
	go build -o report . 2>&1
	echo "exit status $?"
}

attempt 'missing.txt'
attempt '../VERSION'
attempt '/etc/hosts'
attempt '"VERSION'
attempt 'VERSION'
