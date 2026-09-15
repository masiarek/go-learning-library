#!/usr/bin/env bash
# The counter's other two rules, broken: one Done too many, and one too few.
# Both programs end with exit status 2. Only the first line of stderr is kept;
# the goroutine trace after it names file paths and goroutine numbers.
#
# The extra Done happens on main's own goroutine, with no Wait in progress, so
# exactly one goroutine can notice it. Move it into a goroutine while main waits
# and the ending varies from run to run: demo/extra_done_tally.sh counts them.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/extra_done.go" <<'GO'
package main

import "sync"

// fetch calls Done itself, and so does its caller: two Dones for one Add.
func fetch(wg *sync.WaitGroup) {
	defer wg.Done()
}

func main() {
	var wg sync.WaitGroup
	wg.Add(1)
	fetch(&wg)
	wg.Done()
	wg.Wait()
}
GO

cat >"$dir/missing_done.go" <<'GO'
package main

import "sync"

func main() {
	var wg sync.WaitGroup
	wg.Add(2) // two tasks counted...
	go func() {
		defer wg.Done()
	}() // ...one started
	wg.Wait()
}
GO

say() { printf '$ %s\n' "$*"; }

cd "$dir"
for name in extra_done missing_done; do
    say "go build $name.go && ./$name"
    go build -trimpath -o "$name" "$name.go"
    "./$name" 2>"$name.err"
    status=$?
    head -n 1 "$name.err"
    echo "exit status $status"
done
