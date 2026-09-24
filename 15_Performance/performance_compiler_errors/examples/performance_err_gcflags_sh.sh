#!/usr/bin/env bash
# Two mistyped compiler flags. -gcflags hands its value to `compile`, so a
# flag it does not know produces compile's usage text (cut to its first line
# here), and an unknown -d=ssa/... phase is refused by name.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

func add(a, b int) int { return a + b }

func main() {
	println(add(2, 3))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go build -gcflags=-mm .'
go build -gcflags=-mm . 2>&1 | sed -n '1,3p'
echo "exit status ${PIPESTATUS[0]}"

say 'go build -gcflags=-d=ssa/check_bec .'
go build -gcflags=-d=ssa/check_bec . 2>&1
echo "exit status ${PIPESTATUS[0]}"

say 'go build -gcflags=-d=ssa/check_bce .'
go build -gcflags=-d=ssa/check_bce . 2>&1
echo "exit status ${PIPESTATUS[0]}"
