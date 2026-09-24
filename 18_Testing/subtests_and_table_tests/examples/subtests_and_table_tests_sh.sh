#!/usr/bin/env bash
# A table of cases, each run as a subtest with t.Run. go test -v names every
# subtest as Parent/case, and -run 'TestParseQuantity/empty' runs one of
# them. The durations go test prints -- "(0.00s)" after a name and the time
# after "ok  example" -- vary, so this script strips them.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >quantity.go <<'GO'
// Package stock parses the quantities on a delivery note.
package stock

import (
	"errors"
	"strconv"
	"strings"
)

// ParseQuantity reads "12 crates" into its number and its unit.
func ParseQuantity(s string) (int, string, error) {
	fields := strings.Fields(s)
	if len(fields) != 2 {
		return 0, "", errors.New("want a number and a unit")
	}
	n, err := strconv.Atoi(fields[0])
	if err != nil {
		return 0, "", err
	}
	return n, fields[1], nil
}
GO

cat >quantity_test.go <<'GO'
package stock

import "testing"

func TestParseQuantity(t *testing.T) {
	cases := []struct {
		name    string
		in      string
		n       int
		unit    string
		wantErr bool
	}{
		{"crates", "12 crates", 12, "crates", false},
		{"negative", "-3 pallets", -3, "pallets", false},
		{"empty", "", 0, "", true},
		{"three fields", "1 2 3", 0, "", true},
		{"not a number", "many crates", 0, "", true},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			n, unit, err := ParseQuantity(c.in)
			if (err != nil) != c.wantErr {
				t.Fatalf("ParseQuantity(%q): err = %v, want an error: %t", c.in, err, c.wantErr)
			}
			if n != c.n || unit != c.unit {
				t.Errorf("ParseQuantity(%q) = %d, %q; want %d, %q", c.in, n, unit, c.n, c.unit)
			}
		})
	}
}
GO

say() { printf '$ %s\n' "$*"; }

# go test's output without what varies: "(0.00s)" after a test's name and
# the time after "ok  example".
tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v'
go test -v >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say "go test -v -run 'TestParseQuantity/empty'"
go test -v -run 'TestParseQuantity/empty' >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say "go test -v -run '/not'"
go test -v -run '/not' >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test -list .'
go test -list . >test.txt 2>&1
status=$?
tidy
echo "exit status $status"
