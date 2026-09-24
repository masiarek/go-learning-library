#!/usr/bin/env bash
# Four ways `go test -bench` ends without measuring anything: a package with
# no test files, a package whose tests hold no benchmark, a -bench pattern
# that is not a regular expression, and a -benchtime that is neither a
# duration nor a count.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >line.go <<'GO'
package example

import "strings"

func Line(fields []string) string { return "order:" + strings.Join(fields, ";") }
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say "go test -bench=. -run='^$'"
go test -bench=. -run='^$' 2>&1 | sed -E 's/\t[0-9.]+s$//'
echo "exit status ${PIPESTATUS[0]}"

cat >line_test.go <<'GO'
package example

import "testing"

func TestLine(t *testing.T) {
	if Line([]string{"a", "b"}) != "order:a;b" {
		t.Fatal("wrong line")
	}
}
GO

say "go test -bench=. -run='^$'    # line_test.go added: a test, no benchmark"
go test -bench=. -run='^$' 2>&1 | sed -E 's/\t[0-9.]+s$//'
echo "exit status ${PIPESTATUS[0]}"

say "go test -bench='Join(' -run='^$'"
go test -bench='Join(' -run='^$' 2>&1 | sed -E 's/\t[0-9.]+s$//'
echo "exit status ${PIPESTATUS[0]}"

say "go test -bench=. -benchtime=fast -run='^$'"
go test -bench=. -benchtime=fast -run='^$' 2>&1 | sed -n '1p'
echo "exit status ${PIPESTATUS[0]}"
