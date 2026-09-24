#!/usr/bin/env bash
# A cleanup on a "tiny" object -- under 16 bytes and holding no pointers --
# may never run, because the runtime packs such objects into a shared 16-byte
# block that is freed only when every object in it is dead. This program
# attaches a cleanup to three objects of each of three shapes, drops them,
# collects, and counts the cleanups that ran. How the tiny ones fare changes
# from run to run, so this is a demo: N runs (default 20), counted.
#
#   bash demo/tiny_objects.sh          # from the lesson folder
#   bash demo/tiny_objects.sh 100
set -u
cd "$(dirname "$0")" || exit 1
runs=${1:-20}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/tiny.go" <<'GO'
package main

import (
	"fmt"
	"runtime"
	"time"
)

// Tiny is 8 pointer-free bytes: a tiny allocation.
type Tiny struct{ fd int }

// WithString holds a pointer (inside the string), so it is not tiny.
type WithString struct {
	fd   int
	addr string
}

// Sixteen is pointer-free but 16 bytes: too big for the tiny allocator.
type Sixteen struct {
	fd     int
	opened int64
}

var closed = make(chan int, 8)

func collect(want int) int {
	got := 0
	for range 20 {
		runtime.GC()
		for got < want {
			select {
			case <-closed:
				got++
				continue
			case <-time.After(50 * time.Millisecond):
			}
			break
		}
		if got == want {
			break
		}
	}
	return got
}

func main() {
	for i := range 3 {
		t := &Tiny{fd: i}
		runtime.AddCleanup(t, func(fd int) { closed <- fd }, i)
	}
	fmt.Println("Tiny {int}: cleanups that ran out of 3:", collect(3))
	for i := range 3 {
		t := &WithString{fd: i, addr: "db-1"}
		runtime.AddCleanup(t, func(fd int) { closed <- fd }, i)
	}
	fmt.Println("WithString {int, string}: cleanups that ran out of 3:", collect(3))
	for i := range 3 {
		t := &Sixteen{fd: i, opened: 1}
		runtime.AddCleanup(t, func(fd int) { closed <- fd }, i)
	}
	fmt.Println("Sixteen {int, int64}: cleanups that ran out of 3:", collect(3))
}
GO
(cd "$dir" && go build tiny.go) || exit 1

echo "go version: $(go version | cut -d' ' -f3), $runs runs of tiny.go:"
for _ in $(seq "$runs"); do
	"$dir/tiny"
done | sort | uniq -c | awk '{ n=$1; $1=""; printf "  %4d runs printed%s\n", n, $0 }'
