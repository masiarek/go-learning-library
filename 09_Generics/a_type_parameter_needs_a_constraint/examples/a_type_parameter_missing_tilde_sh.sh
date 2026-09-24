#!/usr/bin/env bash
# A constraint written as int | float64 admits exactly those two types. A named
# type such as Celsius, whose underlying type is float64, is not in that set --
# and the compiler says what is missing.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/missing_tilde.go" <<'GO'
package main

import "fmt"

type Exact interface{ int | float64 }

type Loose interface{ ~int | ~float64 }

type Celsius float64

func SumExact[T Exact](values []T) T {
	var total T
	for _, v := range values {
		total += v
	}
	return total
}

func SumLoose[T Loose](values []T) T {
	var total T
	for _, v := range values {
		total += v
	}
	return total
}

func main() {
	readings := []Celsius{21.5, 19}
	fmt.Println(SumLoose(readings))
	fmt.Println(SumExact(readings))
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build missing_tilde.go'
(cd "$dir" && go build missing_tilde.go) 2>&1
echo "exit status $?"
