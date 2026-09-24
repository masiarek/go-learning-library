#!/usr/bin/env bash
# The parameter is a function, but it does not return bool: once a callback
# that returns nothing, once one that returns an error.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/no_bool.go" <<'GO'
package main

import "fmt"

// Readings calls handle for each reading, and cannot be told to stop.
func Readings(handle func(int)) {
	handle(21)
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
}
GO

cat >"$dir/returns_error.go" <<'GO'
package main

import "fmt"

// Readings reports a problem through yield's result instead of a bool.
func Readings(yield func(int) error) {
	_ = yield(21)
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build no_bool.go'
(cd "$dir" && go build no_bool.go) 2>&1
echo "exit status $?"

say 'go build returns_error.go'
(cd "$dir" && go build returns_error.go) 2>&1
echo "exit status $?"
