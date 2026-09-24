#!/usr/bin/env bash
# unsafeptr flags a conversion from a uintptr variable to unsafe.Pointer. It
# judges the form of the expression, not what happens at run time: the second
# program keeps to the documented forms and is vet-clean, although one of its
# pointers is past the end of its allocation and the other is a uintptr that
# reaches a system call from a variable.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

mkdir flagged clean

cat >flagged/main.go <<'GO'
package main

import (
	"fmt"
	"unsafe"
)

// A handle that stores an address as an integer.
type handle struct{ addr uintptr }

func main() {
	readings := new([4]float64)
	h := handle{addr: uintptr(unsafe.Pointer(readings))}
	back := (*[4]float64)(unsafe.Pointer(h.addr))
	fmt.Println(back[0])
}
GO

cat >clean/main.go <<'GO'
package main

import (
	"fmt"
	"syscall"
	"unsafe"
)

func main() {
	buf := make([]byte, 8)
	// Same expression, so vet accepts it -- but it points one past the end.
	end := unsafe.Pointer(uintptr(unsafe.Pointer(&buf[0])) + uintptr(len(buf)))
	// A uintptr that reaches the system call from a variable, not from the call's argument list.
	addr := uintptr(unsafe.Pointer(&buf[0]))
	_, _, errno := syscall.Syscall(syscall.SYS_GETPID, addr, 0, 0)
	fmt.Println(end != nil, errno)
}
GO

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet ./flagged'
go vet ./flagged 2>&1
echo "exit status $?"

say 'go vet ./clean'
go vet ./clean 2>&1
echo "exit status $?"
