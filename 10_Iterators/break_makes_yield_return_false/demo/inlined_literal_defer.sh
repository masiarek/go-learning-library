#!/usr/bin/env bash
# A defer in a range-over-func loop body belongs to the function around the
# loop. When that function is a function literal that the compiler inlines
# into its caller, go1.25.5 runs the deferred call when the CALLER returns.
# This script builds the same program twice, with inlining on and off, and
# prints both outputs, so the difference can be seen on your Go.
#
#   bash demo/inlined_literal_defer.sh     # from the lesson folder
set -u
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/literal.go" <<'GO'
package main

import "fmt"

func Two(yield func(int) bool) {
	_ = yield(1) && yield(2)
}

func main() {
	func() {
		for n := range Two {
			defer fmt.Println("literal: deferred in the body for", n)
		}
		fmt.Println("literal: loop ended, literal still running")
	}()
	fmt.Println("main: the literal returned")
}
GO

go version
for flags in "" "-gcflags=-l"; do
	echo
	echo "go build $flags literal.go && ./literal"
	(cd "$dir" && go build $flags -o literal literal.go && ./literal)
done
