#!/usr/bin/env bash
# runtime.Goexit in main: main's goroutine ends and its deferred calls run, but
# func main never returns -- so the program does not exit, and the worker goes
# on. When the worker ends too, no goroutine is left, and the runtime stops the
# program with a fatal error and exit status 2. The script prints stdout, the
# fatal error line from stderr, and the exit status.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/goexit.go" <<'GO'
package main

import (
	"fmt"
	"runtime"
	"time"
)

func main() {
	mainEnding := make(chan struct{})
	defer func() {
		fmt.Println("main:   deferred calls run")
		close(mainEnding)
	}()

	go func() {
		<-mainEnding
		time.Sleep(1 * time.Second)
		fmt.Println("worker: still running a second later")
	}()

	fmt.Println("main:   calling runtime.Goexit")
	runtime.Goexit()
}
GO

say() { printf '$ %s\n' "$*"; }

cd "$dir" || exit 1
say 'go build goexit.go'
go build goexit.go || exit 1

say './goexit'
./goexit 2>stderr.txt
status=$?
grep '^fatal error: ' stderr.txt
echo "exit status $status"
