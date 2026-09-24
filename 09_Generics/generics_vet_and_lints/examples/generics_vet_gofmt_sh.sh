#!/usr/bin/env bash
# gofmt -s: inside a composite literal whose element type is already known,
# each element's type may be left out -- and an instantiated Pair[string, int]
# is exactly the kind of type worth not repeating.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >literals.go <<'GO'
package main

import "fmt"

type Pair[K comparable, V any] struct {
	Key K
	Val V
}

func main() {
	stock := []Pair[string, int]{Pair[string, int]{"pear", 4}, Pair[string, int]{"apple", 7}}
	byName := map[string]Pair[string, int]{"pear": Pair[string, int]{"pear", 4}}
	fmt.Println(stock, byName)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'gofmt -l literals.go'
gofmt -l literals.go
echo "exit status $?"

say 'gofmt -s -l literals.go'
gofmt -s -l literals.go
echo "exit status $?"

say 'gofmt -s -d literals.go'
gofmt -s -d literals.go
echo "exit status $?"
