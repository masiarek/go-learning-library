#!/usr/bin/env bash
# vet's `unusedresult` analyzer: calling a Builder's String() and dropping the
# result does nothing -- String neither resets nor flushes the Builder -- and
# vet names the call. The fixed version returns it.
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

var line string

func label(parts []string) {
	var b strings.Builder
	for _, p := range parts {
		b.WriteString(p)
	}
	b.String() // meant to be: line = b.String()
}

func main() {
	label([]string{"order:", "42"})
	fmt.Printf("%q\n", line)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet .'
go vet . 2>&1
echo "exit status $?"

say 'sed -i.bak "s/^\tb.String() .*/\tline = b.String()/" main.go && go vet . && go run .'
sed -i.bak 's/^\tb.String() .*/\tline = b.String()/' main.go && go vet . 2>&1 && go run .
echo "exit status $?"
