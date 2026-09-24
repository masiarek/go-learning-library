#!/usr/bin/env bash
# In package list mode -- go test with a package argument, here "." -- a
# passing result is cached, and the second run prints "(cached)" instead of
# a time. -count=1 asks for a real run. In local directory mode, plain
# "go test", nothing is cached. -failfast stops at the first failing test.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >stock_test.go <<'GO'
package stock

import "testing"

func TestCrates(t *testing.T)  {}
func TestPallets(t *testing.T) {}
GO

say() { printf '$ %s\n' "$*"; }

# Keep "(cached)"; drop a time.
tidy() {
	sed -E 's/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/; s/ \([0-9.]+s\)$//' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test .'
go test . >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test .     # the same package, the same tests: served from the cache'
go test . >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test -count=1 .'
go test -count=1 . >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test          # local directory mode: never cached'
go test >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

cat >failing_test.go <<'GO'
package stock

import "testing"

func TestFirstFails(t *testing.T)  { t.Error("the first failure") }
func TestSecondFails(t *testing.T) { t.Error("the second failure") }
GO

say "go test -v -run Fails"
go test -v -run Fails >test.txt 2>&1
status=$?
tidy | grep -E '^(=== RUN|--- |FAIL|ok)'
echo "exit status $status"

say "go test -v -failfast -run Fails"
go test -v -failfast -run Fails >test.txt 2>&1
status=$?
tidy | grep -E '^(=== RUN|--- |FAIL|ok)'
echo "exit status $status"
