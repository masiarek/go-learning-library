#!/usr/bin/env bash
# The linker's -X flag: a var that is not a string is refused with its type
# named; an argument without the importpath.name=value shape is refused by
# the linker itself (its message starts with the linker's own path, replaced
# here by the word link); and a name that no package declares is accepted
# without a word, which is the one to watch for.
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

var (
	version = "dev"
	build   = 0
)

func main() { fmt.Printf("version=%q build=%d\n", version, build) }
GO

say 'go build -ldflags "-X main.build=7" -o report .'
go build -ldflags "-X main.build=7" -o report . 2>&1
echo "exit status $?"

say 'go build -ldflags "-X version=1.4.2" -o report .'
go build -ldflags "-X version=1.4.2" -o report . 2>&1 | sed -E 's#^.*/link: #link: #'
echo "exit status ${PIPESTATUS[0]}"

say 'go build -ldflags "-X main.Version=1.4.2" -o report . && ./report'
go build -ldflags "-X main.Version=1.4.2" -o report . 2>&1 && ./report
echo "exit status $?"

say 'go build -ldflags "-X main.version=1.4.2" -o report . && ./report'
go build -ldflags "-X main.version=1.4.2" -o report . 2>&1 && ./report
echo "exit status $?"
