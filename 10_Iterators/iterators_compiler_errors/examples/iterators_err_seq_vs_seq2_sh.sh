#!/usr/bin/env bash
# A Seq used where a Seq2 is needed: two iteration variables over a
# one-value iterator, and a Seq[int] assigned to a Seq2[int, int].
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/seq_vs_seq2.go" <<'GO'
package main

import (
	"fmt"
	"iter"
	"slices"
)

func main() {
	readings := slices.Values([]int{21, 19, 23})
	for i, r := range readings {
		fmt.Println(i, r)
	}
	var indexed iter.Seq2[int, int] = readings
	_ = indexed
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build seq_vs_seq2.go'
(cd "$dir" && go build seq_vs_seq2.go) 2>&1
echo "exit status $?"
