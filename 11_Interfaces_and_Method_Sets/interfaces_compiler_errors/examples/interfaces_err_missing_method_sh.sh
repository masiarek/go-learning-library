#!/usr/bin/env bash
# Two ways to fall short of an interface: Square has Area with the wrong
# result type, Circle has no Area at all. The compiler says which, and for
# the wrong signature prints what it has and what it wants.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/shapes.go" <<'GO'
package main

import "fmt"

type Shape interface{ Area() float64 }

type Square struct{ Side float64 }

func (s Square) Area() int { return int(s.Side * s.Side) }

type Circle struct{ Radius float64 }

func main() {
	shapes := []Shape{Square{2}, Circle{1}}
	fmt.Println(len(shapes))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build shapes.go'
(cd "$dir" && go build shapes.go) 2>&1
echo "exit status $?"
