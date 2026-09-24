#!/usr/bin/env bash
# Three ways out of main that are not a return, and what each does with the
# deferred calls: a panic runs them and exits 2; os.Exit runs none and exits
# with the status it was given; runtime.Goexit from main runs them, and then
# the runtime stops the program because main's goroutine is gone. The
# goroutine traces on stderr carry addresses that change between runs, so
# only the first line of each program's stderr is kept.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/panics.go" <<'GO'
package main

import "fmt"

func main() {
	defer fmt.Println("deferred: unlock the ledger")
	fmt.Println("main: posting invoice 18")
	panic("invoice 18 has no customer")
}
GO

cat >"$dir/exits.go" <<'GO'
package main

import (
	"fmt"
	"os"
)

func main() {
	defer fmt.Println("deferred: unlock the ledger")
	fmt.Println("main: posting invoice 18, then os.Exit(3)")
	os.Exit(3)
}
GO

cat >"$dir/goexit.go" <<'GO'
package main

import (
	"fmt"
	"runtime"
)

func main() {
	defer fmt.Println("deferred: unlock the ledger")
	fmt.Println("main: calling runtime.Goexit")
	runtime.Goexit()
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

for program in panics exits goexit; do
	say "go build $program.go"
	go build "$program.go" || exit 1
	say "./$program"
	"./$program" 2>stderr.txt
	status=$?
	head -n 1 stderr.txt
	echo "exit status $status"
done
