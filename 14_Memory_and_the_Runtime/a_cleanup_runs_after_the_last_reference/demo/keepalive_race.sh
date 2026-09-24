#!/usr/bin/env bash
# Without runtime.KeepAlive, a cleanup may run while a function is still
# using a resource it took out of the object. This program takes f.fd, then
# forces a collection and waits up to 300 ms for the cleanup, then would use
# fd. How often the cleanup gets there first changes from run to run, so
# this is a demo: it runs the program N times (default 50) and counts.
#
#   bash demo/keepalive_race.sh          # from the lesson folder
#   bash demo/keepalive_race.sh 200
set -u
cd "$(dirname "$0")" || exit 1
runs=${1:-50}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/race.go" <<'GO'
package main

import (
	"fmt"
	"runtime"
	"time"
)

type File struct{ fd int }

var closed = make(chan int, 1)

func open(fd int) *File {
	f := &File{fd: fd}
	runtime.AddCleanup(f, func(fd int) { closed <- fd }, fd)
	return f
}

// closedBeforeUse forces collections between taking f.fd and using it.
func closedBeforeUse(fd int) bool {
	runtime.GC()
	runtime.GC()
	select {
	case <-closed:
		return true
	case <-time.After(300 * time.Millisecond):
		return false
	}
}

func main() {
	f := open(3)
	fd := f.fd
	// f is never mentioned again: from here on it is dead, whatever its scope.
	fmt.Println("closed before the fd was used:", closedBeforeUse(fd))
}
GO
(cd "$dir" && go build race.go) || exit 1

echo "go version: $(go version | cut -d' ' -f3), $runs runs of race.go:"
for _ in $(seq "$runs"); do
	"$dir/race"
done | sort | uniq -c | awk '{ n=$1; $1=""; printf "  %4d runs printed%s\n", n, $0 }'
