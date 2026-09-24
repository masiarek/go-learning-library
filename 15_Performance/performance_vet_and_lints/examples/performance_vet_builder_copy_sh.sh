#!/usr/bin/env bash
# A strings.Builder copied by value. vet's copylocks analyzer is for locks and
# says nothing here; the Builder catches the copy itself, at the first write
# through the copy, with a panic.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

import (
	"fmt"
	"strings"
)

// appendReference takes the Builder by value: a copy of its header, sharing
// the bytes written so far.
func appendReference(b strings.Builder, reference string) string {
	b.WriteString(reference)
	return b.String()
}

func main() {
	var b strings.Builder
	b.WriteString("order:")
	fmt.Println(appendReference(b, "PO-2026-000418"))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet .'
go vet . 2>&1
echo "exit status $?"

say 'go build -o order . && ./order'
go build -o order . && ./order 2>stderr.txt
status=$?
grep '^panic:' stderr.txt
echo "exit status $status"
