#!/usr/bin/env bash
# go vet has no analyzer for a defer inside a loop: the program below opens a
# file per iteration and defers every Close to the end of the function, and
# vet prints nothing and exits 0. Tools outside the Go distribution name it
# (the page links them); none of them runs here.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/all_at_the_end.go" <<'GO'
package main

import (
	"fmt"
	"os"
)

func sizes(paths []string) (total int64, err error) {
	for _, path := range paths {
		f, err := os.Open(path)
		if err != nil {
			return 0, err
		}
		defer f.Close() // runs when sizes returns, not at the end of this iteration
		info, err := f.Stat()
		if err != nil {
			return 0, err
		}
		total += info.Size()
	}
	return total, nil
}

func main() {
	total, err := sizes(os.Args[1:])
	fmt.Println(total, err)
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go vet all_at_the_end.go'
go vet all_at_the_end.go
echo "exit status $?"
