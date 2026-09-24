#!/usr/bin/env bash
# Recovering a panic and panicking again keeps the program's failure: exit
# status 2 either way. Since Go 1.25 a re-panic with the same value prints one
# line, "[recovered, repanicked]"; a panic with a new value prints the first
# panic marked "[recovered]" and the new one under it. The goroutine traces
# carry addresses, so only the panic lines are kept.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/same_value.go" <<'GO'
package main

import "fmt"

func main() {
	defer func() {
		r := recover()
		fmt.Println("recovered:", r, "-- cannot handle it here, panicking again")
		panic(r)
	}()
	panic("invoice 18 has no customer")
}
GO

cat >"$dir/new_value.go" <<'GO'
package main

import "fmt"

func main() {
	defer func() {
		r := recover()
		panic(fmt.Errorf("posting invoices: %v", r))
	}()
	panic("invoice 18 has no customer")
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

for program in same_value new_value; do
	say "go build $program.go"
	go build "$program.go" || exit 1
	say "./$program"
	"./$program" 2>stderr.txt
	status=$?
	grep 'panic:' stderr.txt
	echo "exit status $status"
done
