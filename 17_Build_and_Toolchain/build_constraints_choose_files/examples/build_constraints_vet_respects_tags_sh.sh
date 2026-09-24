#!/usr/bin/env bash
# go vet sees the same files the build would. A Printf mistake in a file
# behind //go:build fast is invisible to a plain go vet and found by
# go vet -tags fast, so a tag-gated file needs its own vet run.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

cat >main.go <<'GO'
package main

func main() {}
GO

cat >report_fast.go <<'GO'
//go:build fast

package main

import "fmt"

func report(orders int) {
	fmt.Printf("orders: %s\n", orders)
}
GO

say 'go vet .'
go vet . 2>&1
echo "exit status $?"
say 'go vet -tags fast .'
go vet -tags fast . 2>&1
echo "exit status $?"
