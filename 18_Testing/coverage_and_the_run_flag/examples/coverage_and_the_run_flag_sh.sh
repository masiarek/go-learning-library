#!/usr/bin/env bash
# go test -cover prints the share of statements the tests ran, and
# -coverprofile plus go tool cover -func breaks it down per function. Both
# are fixed for fixed code and fixed tests, so they are the key. A third test
# case reaches the last untested branch and the figure rises to 100%.
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

// Plural returns the unit's plural for a count.
func Plural(n int, unit string) string {
	if n == 1 {
		return unit
	}
	return unit + "s"
}
GO

cat >quantity_test.go <<'GO'
package stock

import "testing"

func TestParseQuantity(t *testing.T) {
	cases := []struct {
		name, in string
		n        int
		unit     string
		wantErr  bool
	}{
		{"crates", "12 crates", 12, "crates", false},
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
GO

say() { printf '$ %s\n' "$*"; }

tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -cover'
go test -cover >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test -coverprofile=cover.out >/dev/null && go tool cover -func=cover.out'
go test -coverprofile=cover.out >/dev/null 2>&1 && go tool cover -func=cover.out
echo "exit status $?"

say 'head -n 3 cover.out'
head -n 3 cover.out

cat >more_test.go <<'GO'
package stock

import "testing"

func TestParseQuantityNotANumber(t *testing.T) {
	if _, _, err := ParseQuantity("many crates"); err == nil {
		t.Error("want an error for a quantity that is not a number")
	}
}

func TestPlural(t *testing.T) {
	if got := Plural(1, "crate"); got != "crate" {
		t.Errorf("Plural(1) = %q", got)
	}
	if got := Plural(3, "crate"); got != "crates" {
		t.Errorf("Plural(3) = %q", got)
	}
}
GO

say 'go test -cover     # with more_test.go added'
go test -cover >test.txt 2>&1
status=$?
tidy
echo "exit status $status"
