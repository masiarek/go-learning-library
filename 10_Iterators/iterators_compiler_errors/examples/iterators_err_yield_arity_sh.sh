#!/usr/bin/env bash
# yield called with the wrong number of values, and a yield function with
# three parameters, which range does not accept.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/yield_arity.go" <<'GO'
package main

import "fmt"

// Readings yields one int; the calls below pass two values, then none.
func Readings(yield func(int) bool) {
	_ = yield(21, "celsius")
	_ = yield()
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
}
GO

cat >"$dir/three_values.go" <<'GO'
package main

import "fmt"

// Readings yields three values per element; range takes at most two.
func Readings(yield func(int, string, bool) bool) {
	_ = yield(21, "celsius", true)
}

func main() {
	for r := range Readings {
		fmt.Println(r)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build yield_arity.go'
(cd "$dir" && go build yield_arity.go) 2>&1
echo "exit status $?"

say 'go build three_values.go'
(cd "$dir" && go build three_values.go) 2>&1
echo "exit status $?"
