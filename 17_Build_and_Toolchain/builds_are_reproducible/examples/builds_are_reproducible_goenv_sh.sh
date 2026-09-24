#!/usr/bin/env bash
# go env -w writes a setting into the go command's own configuration file,
# and every later build reads it. GOENV points that file into this script's
# temporary directory, so the user's real configuration is never touched.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOENV="$dir/go.env"

say() { printf '$ %s\n' "$*"; }
same() { if cmp -s "$1" "$2"; then echo "identical: yes"; else echo "identical: no"; fi; }

go mod init example >/dev/null 2>&1 || exit 1
cat >main.go <<'GO'
package main

import "fmt"

func main() {
	fmt.Println("invoice printer")
}
GO
go build -trimpath -o trimmed . || exit 1

say 'go env GOFLAGS'
go env GOFLAGS
say 'go env -w GOFLAGS=-trimpath'
go env -w GOFLAGS=-trimpath
say 'cat "$GOENV"'
cat "$GOENV"
say 'go env GOFLAGS'
go env GOFLAGS
say 'go build -o configured . && cmp trimmed configured'
go build -o configured . && same trimmed configured

say 'go env -u GOFLAGS && go env GOFLAGS'
go env -u GOFLAGS && go env GOFLAGS

say 'go env -w NOTAVAR=1'
go env -w NOTAVAR=1 2>&1
echo "exit status $?"
