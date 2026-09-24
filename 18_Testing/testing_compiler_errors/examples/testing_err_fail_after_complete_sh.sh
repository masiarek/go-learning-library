#!/usr/bin/env bash
# A goroutine started by a test that calls t.Error after the test has
# returned: the testing package panics, because there is no test left to
# fail. Here the goroutine waits for the next test to start, so that the
# first test has certainly completed.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >stock_test.go <<'GO'
package stock

import "testing"

var nextTestStarted = make(chan struct{})

func TestBins(t *testing.T) {
	go func() {
		<-nextTestStarted
		t.Error("the bin count is off") // TestBins returned long ago
	}()
}

func TestPallets(t *testing.T) {
	close(nextTestStarted)
	select {} // wait; the panic ends the process
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v'
go test -v >test.txt 2>&1
status=$?
sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt | grep -E '^(=== |--- |panic:|FAIL|ok|PASS|exit status)'
echo "exit status $status"
