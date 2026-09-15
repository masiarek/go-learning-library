#!/usr/bin/env bash
# A receive from a nil channel blocks forever, and so does a select whose every
# channel is nil. With no other goroutine left to wake main, the runtime ends
# the program with a fatal error. The goroutine dump after it names files and
# addresses that vary, so this script keeps the fatal error, the state the dump
# gives main, and the exit status.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/nil_receive.go" <<'GO'
package main

import "fmt"

func main() {
	var readings chan string // declared, never made: nil
	fmt.Println("main: receiving from a nil channel")
	<-readings
}
GO

cat >"$dir/nil_select.go" <<'GO'
package main

import "fmt"

func main() {
	var readings, alarms chan string // both nil
	fmt.Println("main: select over two nil channels, no default")
	select {
	case <-readings:
	case <-alarms:
	}
}
GO

say() { printf '$ %s\n' "$*"; }

for program in nil_receive nil_select; do
    say "go build $program.go && ./$program"
    (cd "$dir" && GOTOOLCHAIN=local go build "$program.go") || exit 1
    (cd "$dir" && "./$program") 2>"$dir/stderr"
    status=$?
    grep '^fatal error' "$dir/stderr"
    # "goroutine 1 [select]:" -- keep the bracket, drop the goroutine number
    grep -m 1 '^goroutine ' "$dir/stderr" | sed -e 's/^goroutine [0-9]* /main goroutine: /' -e 's/:$//'
    echo "exit status $status"
done
