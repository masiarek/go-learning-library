#!/usr/bin/env bash
# A Seq[int] passed and assigned where a Seq[string] is wanted. Seq is
# generic, and Seq[int] and Seq[string] are two unrelated types.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/wrong_element.go" <<'GO'
package main

import (
	"fmt"
	"iter"
	"slices"
)

// printLabels prints the labels of a sequence of strings.
func printLabels(labels iter.Seq[string]) {
	for l := range labels {
		fmt.Println(l)
	}
}

func main() {
	readings := slices.Values([]int{21, 19, 23})
	printLabels(readings)
	var labels iter.Seq[string] = readings
	_ = labels
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build wrong_element.go'
(cd "$dir" && go build wrong_element.go) 2>&1
echo "exit status $?"
