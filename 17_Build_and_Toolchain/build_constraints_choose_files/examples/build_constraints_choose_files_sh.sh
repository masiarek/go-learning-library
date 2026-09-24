#!/usr/bin/env bash
# Two files define pricing() under opposite constraints, //go:build fast and
# //go:build !fast. Which one is compiled in depends on -tags, and go list
# shows the choice without building anything. The platform files at the end
# (_linux.go, _windows.go, _amd64.go, _arm64.go) are listed under a GOOS and
# GOARCH set by hand, so this script prints the same thing on every machine.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

cat >main.go <<'GO'
package main

import "fmt"

func main() {
	fmt.Println("pricing:", pricing())
}
GO

cat >pricing_fast.go <<'GO'
//go:build fast

package main

func pricing() string { return "fast path, compiled in with -tags fast" }
GO

cat >pricing_careful.go <<'GO'
//go:build !fast

package main

func pricing() string { return "careful path, the default" }
GO

cat >audit.go <<'GO'
//go:build fast && !debug

package main

import "fmt"

func init() { fmt.Println("audit.go: compiled in, because fast && !debug") }
GO

say 'gofmt -l .'
gofmt -l .

say 'go run .'
go run .
say 'go run -tags fast .'
go run -tags fast .
say 'go run -tags fast,debug .'
go run -tags fast,debug .

say "go list -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' ."
go list -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' .
say "go list -tags fast -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' ."
go list -tags fast -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' .

# Platform files: the suffix is the constraint, so no //go:build line is needed.
rm audit.go
for name in clock_linux clock_windows clock_darwin clock_amd64 clock_arm64; do
	printf 'package main\n' >"$name.go"
done
say "GOOS=linux GOARCH=amd64 go list -f '{{.GoFiles}}' ."
GOOS=linux GOARCH=amd64 go list -f '{{.GoFiles}}' .
say "GOOS=windows GOARCH=arm64 go list -f '{{.GoFiles}}' ."
GOOS=windows GOARCH=arm64 go list -f '{{.GoFiles}}' .
say "GOOS=windows GOARCH=arm64 go list -tags fast -f '{{.GoFiles}}' ."
GOOS=windows GOARCH=arm64 go list -tags fast -f '{{.GoFiles}}' .
