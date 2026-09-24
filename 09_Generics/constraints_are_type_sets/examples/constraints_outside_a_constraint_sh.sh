#!/usr/bin/env bash
# An interface with a union is a type set, not a type: it may constrain a type
# parameter and nothing else. And a type that is in the union but lacks the
# method is outside the set.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/outside.go" <<'GO'
package main

import "fmt"

type Quantity interface {
	~int | ~float64
	Unit() string
}

type Grams int

func (Grams) Unit() string { return "g" }

func Total[T Quantity](values []T) string {
	var total T
	for _, v := range values {
		total += v
	}
	return fmt.Sprintf("%v %s", total, total.Unit())
}

// Describe wants "any quantity" as an ordinary interface value.
func Describe(q Quantity) string { return q.Unit() }

func main() {
	var pending []Quantity
	fmt.Println(Total([]Grams{250}), pending)
	fmt.Println(Total([]int{250}))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build outside.go'
(cd "$dir" && go build outside.go) 2>&1
echo "exit status $?"
