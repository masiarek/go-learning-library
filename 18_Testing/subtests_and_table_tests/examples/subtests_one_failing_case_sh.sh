#!/usr/bin/env bash
# One case in the table is wrong. Its subtest fails, the other subtests still
# run and report, and go test exits 1. A second test file shows the
# difference between t.Error, which records the failure and carries on, and
# t.Fatal, which records it and ends that subtest at once.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >quantity.go <<'GO'
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
		{"pallets", "7 pallets", 7, "pallet", false}, // the table is wrong: the unit is "pallets"
		{"empty", "", 0, "", true},
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

// Two checks fail in each of these. t.Error reports both; t.Fatal reports
// the first and stops.
func TestErrorCarriesOn(t *testing.T) {
	n, unit, _ := ParseQuantity("12 crates")
	if n != 13 {
		t.Errorf("n = %d, want 13", n)
	}
	if unit != "crate" {
		t.Errorf("unit = %q, want %q", unit, "crate")
	}
}

func TestFatalStops(t *testing.T) {
	n, unit, _ := ParseQuantity("12 crates")
	if n != 13 {
		t.Fatalf("n = %d, want 13", n)
	}
	if unit != "crate" {
		t.Fatalf("unit = %q, want %q", unit, "crate")
	}
}
GO

say() { printf '$ %s\n' "$*"; }

tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v -run TestParseQuantity'
go test -v -run TestParseQuantity >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say "go test -v -run 'TestErrorCarriesOn|TestFatalStops'"
go test -v -run 'TestErrorCarriesOn|TestFatalStops' >test.txt 2>&1
status=$?
tidy
echo "exit status $status"
