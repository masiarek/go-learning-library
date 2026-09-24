#!/usr/bin/env bash
# go build -gcflags=-m is the lens for boxing: the compiler says which values
# it moves to the heap when they are converted to an interface and kept. Only
# the escape lines are kept here; the inlining decisions are noise for this
# question.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

var kept any

//go:noinline
func keepValue(quantity int) { kept = quantity }

//go:noinline
func keepPointer(order *[2]int) { kept = order }

func main() {
	keepValue(300)
	keepPointer(&[2]int{1, 2})
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go build -gcflags=-m . 2>&1 | grep -E "escapes|leaking|moved"'
go build -gcflags=-m . 2>&1 | grep -E "escapes|leaking|moved"
echo "exit status $?"
