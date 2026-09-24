#!/usr/bin/env bash
# The uintptr round trip: an address kept as an integer and converted back to
# a pointer later. go vet's unsafeptr analyzer flags the conversion; the
# program still builds and runs. Built with -d=checkptr -- which -race turns on
# as well -- the same conversion is a fatal error at run time. The stderr also
# carries a goroutine trace with a temporary path, so only the fatal error
# line is printed.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >roundtrip.go <<'GO'
package main

import (
	"fmt"
	"runtime"
	"unsafe"
)

type Reading struct {
	Station uint16
	Value   float64
}

//go:noinline
func newReadings() *[4]Reading {
	return &[4]Reading{{1, 20.5}, {2, 21}, {3, 19.75}, {4, 22}}
}

func main() {
	readings := newReadings()
	addr := uintptr(unsafe.Pointer(readings)) // an integer, not a reference
	runtime.GC()
	again := (*[4]Reading)(unsafe.Pointer(addr)) // the mistake: uintptr -> Pointer from a variable
	fmt.Println("first reading through the round trip:", again[0])
	runtime.KeepAlive(readings)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet ./...'
go vet ./... 2>&1
echo "exit status $?"

say 'go build -o roundtrip . && ./roundtrip'
go build -o roundtrip . && ./roundtrip
echo "exit status $?"

say 'go build -gcflags=all=-d=checkptr -o roundtrip_checkptr . && ./roundtrip_checkptr'
go build -gcflags=all=-d=checkptr -o roundtrip_checkptr . || exit 1
./roundtrip_checkptr 2>stderr.txt
status=$?
grep '^fatal error:' stderr.txt
echo "exit status $status"

# -race needs cgo, and on Linux a C compiler; without them this stops here.
say 'go build -race -o roundtrip_race . && ./roundtrip_race'
go build -race -o roundtrip_race . || exit 1
./roundtrip_race 2>stderr.txt
status=$?
grep '^fatal error:' stderr.txt
echo "exit status $status"
