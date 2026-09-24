#!/usr/bin/env bash
# What go generate hands the command: $GOFILE, $GOPACKAGE and $GOLINE name the
# directive's place, $DOLLAR is a literal $. A directive must start at column
# 0 with no space after //. -n prints commands without running them, -run
# picks a subset, a command that fails stops the run, and a file the build
# would leave out is left out here too -- unless its tag is "generate".
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

cat >orders.go <<'GO'
package orders

//go:generate echo file=$GOFILE package=$GOPACKAGE line=$GOLINE literal=$DOLLAR
GO

cat >invoices.go <<'GO'
package orders

//go:generate echo file=$GOFILE line=$GOLINE
// go:generate echo never printed: a space after //
GO

cat >tagged.go <<'GO'
//go:build generate

package orders

//go:generate echo from tagged.go, which go build never compiles
GO

cat >skipped.go <<'GO'
//go:build never

package orders

//go:generate echo never printed: skipped.go is excluded by its constraint
GO

say 'go generate -n ./...'
go generate -n ./... 2>&1
say 'go generate ./...'
go generate ./... 2>&1
say 'go generate -run literal ./...'
go generate -run literal ./... 2>&1
say "go list -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' ."
go list -f '{{.GoFiles}} ignored={{.IgnoredGoFiles}}' .

cat >failing.go <<'GO'
package orders

//go:generate false
GO
say 'go generate ./...'
go generate ./... 2>&1
echo "exit status $?"
