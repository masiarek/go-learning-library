#!/usr/bin/env bash
# go vet's waitgroup analyzer, new in Go 1.25, on the mistake this lesson is
# about: wg.Add called inside the goroutine it is meant to count. Two loops make
# it: in the first, Add opens the goroutine; in the second, a Println comes first.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/main.go" <<'GO'
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	for _, url := range []string{"/a", "/b", "/c"} {
		go func() {
			wg.Add(1)
			defer wg.Done()
			fmt.Println("fetched", url)
		}()
	}
	wg.Wait()

	for _, url := range []string{"/d", "/e", "/f"} {
		go func() {
			fmt.Println("fetching", url)
			wg.Add(1)
			defer wg.Done()
			fmt.Println("fetched", url)
		}()
	}
	wg.Wait()
}
GO

say() { printf '$ %s\n' "$*"; }

cd "$dir"
say 'go mod init example'
go mod init example >/dev/null 2>&1

say "grep -n 'wg.Add' main.go"
grep -n 'wg.Add' main.go

say 'go build .'
go build -o /dev/null . 2>&1
echo "exit status $?"

say 'go vet .'
go vet . 2>&1
echo "exit status $?"
