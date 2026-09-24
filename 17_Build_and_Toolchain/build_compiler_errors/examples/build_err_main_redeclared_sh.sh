#!/usr/bin/env bash
# Every .go file in a directory that the build does not exclude is part of
# one package, so two files that each declare main collide, and a file with a
# different package clause makes the directory two packages, which is refused
# before compilation starts. That second message names the directory, which
# this script replaces with $dir.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

cat >main.go <<'GO'
package main

import "fmt"

func main() { fmt.Println("orders: 3") }
GO

cat >scratch.go <<'GO'
package main

func main() {}
GO

say 'go build -o report .'
go build -o report . 2>&1
echo "exit status $?"

cat >scratch.go <<'GO'
package scratch

func main() {}
GO

say 'go build -o report .'
go build -o report . 2>&1 | sed "s#$dir#\$dir#"
echo "exit status ${PIPESTATUS[0]}"

say 'rm scratch.go && go build -o report . && ./report'
rm scratch.go && go build -o report . 2>&1 && ./report
echo "exit status $?"
