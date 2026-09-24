#!/usr/bin/env bash
# The same source built twice gives the same bytes -- after the source is
# touched, and from a different directory, as long as -trimpath keeps the
# build directory out of the binary. Without it, two checkouts of one commit
# build two different binaries, and each names the directory it came from.
# Stamping a version with -X changes the bytes, because the version is an
# input. Nothing here prints a path, a hash or a size.
set -u
export GOTOOLCHAIN=local

first=$(mktemp -d)
second=$(mktemp -d)
trap 'rm -rf "$first" "$second"' EXIT

say() { printf '$ %s\n' "$*"; }
same() { if cmp -s "$1" "$2"; then echo "identical: yes"; else echo "identical: no"; fi; }

# One module in two directories: two people who checked out the same commit.
for dir in "$first" "$second"; do
	(cd "$dir" && go mod init example >/dev/null 2>&1) || exit 1
	cat >"$dir/main.go" <<'GO'
package main

import "fmt"

var version = "dev"

func main() {
	fmt.Println("invoice printer", version)
}
GO
done
cd "$first" || exit 1

say 'go build -trimpath -o one . && go build -trimpath -o two . && cmp one two'
go build -trimpath -o one . && go build -trimpath -o two . && same one two

say 'touch main.go && go build -trimpath -o three . && cmp one three'
touch main.go && go build -trimpath -o three . && same one three

say '(cd "$second" && go build -trimpath -o four .) && cmp one "$second/four"'
(cd "$second" && go build -trimpath -o four .) && same one "$second/four"

say 'go build -o plain . && (cd "$second" && go build -o plain .) && cmp plain "$second/plain"'
go build -o plain . && (cd "$second" && go build -o plain .) && same plain "$second/plain"

say 'grep -qF "$first" plain; grep -qF "$first" one'
if grep -qF "$first" plain; then echo "plain names its build directory: yes"; else echo "plain names its build directory: no"; fi
if grep -qF "$first" one; then echo "one names its build directory: yes"; else echo "one names its build directory: no"; fi

say 'GOFLAGS=-trimpath go build -o five . && cmp one five'
GOFLAGS=-trimpath go build -o five . && same one five

say 'go version -m one | grep trimpath'
go version -m one | grep trimpath

say 'go build -trimpath -ldflags "-X main.version=1.4.2" -o six . && cmp one six'
go build -trimpath -ldflags "-X main.version=1.4.2" -o six . && same one six
say './one; ./six'
./one
./six
