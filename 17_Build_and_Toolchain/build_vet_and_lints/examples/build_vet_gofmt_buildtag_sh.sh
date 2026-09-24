#!/usr/bin/env bash
# gofmt on build constraints: it inserts the blank line after //go:build
# that separates the constraint from the package comment, and above an old
# // +build line it writes the //go:build line that Go 1.17 introduced. go
# list shows that the constraint held either way.
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

cat >pricing_fast.go <<'GO'
//go:build fast
package main

func pricing() string { return "fast" }
GO
say 'gofmt -d pricing_fast.go   # no blank line after //go:build'
gofmt -d pricing_fast.go
say "go list -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' ."
go list -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' .

cat >pricing_fast.go <<'GO'
// +build fast

package main

func pricing() string { return "fast" }
GO
say 'gofmt -d pricing_fast.go   # only the old +build line'
gofmt -d pricing_fast.go
say 'go vet .'
go vet . 2>&1
echo "exit status $?"
say "go list -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' ."
go list -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' .

say 'gofmt -w pricing_fast.go && gofmt -l . && head -3 pricing_fast.go'
gofmt -w pricing_fast.go && gofmt -l . && head -3 pricing_fast.go
