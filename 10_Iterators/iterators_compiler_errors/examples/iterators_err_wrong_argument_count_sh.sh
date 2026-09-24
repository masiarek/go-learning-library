#!/usr/bin/env bash
# The function has the wrong number of parameters for a range: an iterator
# with a second parameter, and a constructor that returns an iterator but was
# not called.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/extra_parameter.go" <<'GO'
package main

import "fmt"

// Readings takes a limit as well as yield, so range cannot call it.
func Readings(yield func(int) bool, limit int) {
	_ = yield(limit)
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
}
GO

cat >"$dir/not_called.go" <<'GO'
package main

import (
	"fmt"
	"iter"
)

// Readings returns an iterator; the iterator is Readings(), not Readings.
func Readings() iter.Seq[int] {
	return func(yield func(int) bool) {
		_ = yield(21)
	}
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build extra_parameter.go'
(cd "$dir" && go build extra_parameter.go) 2>&1
echo "exit status $?"

say 'go build not_called.go'
(cd "$dir" && go build not_called.go) 2>&1
echo "exit status $?"
