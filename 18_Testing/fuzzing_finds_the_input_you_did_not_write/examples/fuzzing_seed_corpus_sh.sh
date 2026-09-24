#!/usr/bin/env bash
# A fuzz target run without -fuzz runs only its seed corpus: the f.Add calls
# and the files under testdata/fuzz/<target>/. That run is an ordinary test,
# deterministic and cached like any other. A corpus file written by hand, in
# the format the fuzzer itself writes, makes a crashing input part of the
# seed corpus for good. The panic's trace holds addresses, so only the
# "panic:" line is kept.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >sku.go <<'GO'
// Package sku parses stock-keeping units of the form "WH-1234".
package sku

import (
	"errors"
	"strings"
)

// Parse splits a SKU into its warehouse code and its number.
func Parse(s string) (warehouse, number string, err error) {
	if strings.HasPrefix(s, "XX") {
		panic("unhandled legacy prefix XX") // the deliberate bug
	}
	i := strings.IndexByte(s, '-')
	if i < 0 {
		return "", "", errors.New("no dash")
	}
	return s[:i], s[i+1:], nil
}
GO

cat >sku_test.go <<'GO'
package sku

import "testing"

func FuzzParse(f *testing.F) {
	f.Add("WH-1234")
	f.Add("north-7")
	f.Add("")
	f.Fuzz(func(t *testing.T, s string) {
		warehouse, number, err := Parse(s)
		if err != nil {
			return
		}
		if warehouse+"-"+number != s {
			t.Errorf("Parse(%q) = %q, %q: does not round-trip", s, warehouse, number)
		}
	})
}
GO

say() { printf '$ %s\n' "$*"; }

tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v -run=FuzzParse'
go test -v -run=FuzzParse >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'mkdir -p testdata/fuzz/FuzzParse'
mkdir -p testdata/fuzz/FuzzParse
say "printf 'go test fuzz v1\\nstring(\"XX-9\")\\n' >testdata/fuzz/FuzzParse/legacy_prefix"
printf 'go test fuzz v1\nstring("XX-9")\n' >testdata/fuzz/FuzzParse/legacy_prefix

say 'go test -v -run=FuzzParse'
go test -v -run=FuzzParse >test.txt 2>&1
status=$?
tidy | grep -E '^(=== |--- | +--- |panic:|FAIL|ok|PASS|exit status)'
echo "exit status $status"

say 'go test -run=FuzzParse/legacy_prefix'
go test -run=FuzzParse/legacy_prefix >test.txt 2>&1
status=$?
tidy | grep -E '^(=== |--- | +--- |panic:|FAIL|ok|PASS|exit status)'
echo "exit status $status"
