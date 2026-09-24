#!/usr/bin/env bash
# printf checks a verb against the type parameter's whole type set: %d on a T
# constrained by any, or by a union with a float or string term, is reported,
# and the message names the term that does not fit. %v fits everything.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
mkdir -p "$dir/bad" "$dir/good"

cat >"$dir/bad/main.go" <<'GO'
package main

import "fmt"

func ShowAny[T any](v T) { fmt.Printf("%d\n", v) }

func ShowNumber[T ~int | ~float64](v T) { fmt.Printf("%d\n", v) }

func ShowLabel[T ~string](v T) { fmt.Printf("%d\n", v) }

func ShowCount[T ~int](v T) { fmt.Printf("%d\n", v) }

func main() {
	ShowAny("pear")
	ShowNumber(2.5)
	ShowLabel("paid")
	ShowCount(7)
}
GO

cat >"$dir/good/main.go" <<'GO'
package main

import "fmt"

func ShowAny[T any](v T) { fmt.Printf("%v\n", v) }

func ShowNumber[T ~int | ~float64](v T) { fmt.Printf("%v\n", v) }

func ShowCount[T ~int](v T) { fmt.Printf("%d\n", v) }

func main() {
	ShowAny("pear")
	ShowNumber(2.5)
	ShowCount(7)
}
GO

say() { printf '$ %s\n' "$*"; }

for variant in bad good; do
	cd "$dir/$variant" || exit 1
	go mod init example >/dev/null 2>&1 || exit 1
	say "cd $variant && go vet ."
	go vet . 2>&1
	echo "exit status $?"
done
