#!/usr/bin/env bash
# The extra Done from examples/a_waitgroup_counts_goroutines_miscount_sh.sh,
# moved into a goroutine while main is in Wait. Which goroutine notices the
# mistake first varies, and so does how the program ends. Run it N times
# (default 200) and count each distinct ending: the exit status and the first
# line of stderr.
#
#   bash demo/extra_done_tally.sh          # from the lesson folder
#   bash demo/extra_done_tally.sh 1000
set -eu
runs=${1:-200}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/extra_done_waiting.go" <<'GO'
package main

import "sync"

// fetch calls Done itself, and so does its caller: two Dones for one Add.
func fetch(wg *sync.WaitGroup) {
	defer wg.Done()
}

func main() {
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		fetch(&wg)
	}()
	wg.Wait()
}
GO

go build -trimpath -o "$dir/extra_done_waiting" "$dir/extra_done_waiting.go"
go version
for _ in $(seq "$runs"); do
    status=0
    "$dir/extra_done_waiting" 2>"$dir/err" || status=$?
    printf 'exit status %s: %s\n' "$status" "$(head -n 1 "$dir/err")"
done | sort | uniq -c | sort -rn
