#!/usr/bin/env bash
# copylocks: a value receiver on a type that holds a sync.Mutex copies the
# lock with every call, so the method locks its own copy and guards nothing.
# vet reports the receiver, a by-value parameter, the call that copies, and a
# plain assignment. With pointer receivers and a pointer parameter it is
# silent.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

import (
	"fmt"
	"sync"
)

type Ledger struct {
	mu      sync.Mutex
	entries int
}

func (l Ledger) Add() { // value receiver: l is a copy, mutex and all
	l.mu.Lock()
	defer l.mu.Unlock()
	l.entries++
}

func report(l Ledger) { fmt.Println(l.entries) }

func main() {
	var l Ledger
	l.Add()
	report(l)
	snapshot := l
	fmt.Println(snapshot.entries)
}
GO

cat >pointers.go <<'GO'
package main

import (
	"fmt"
	"sync"
)

type Ledger struct {
	mu      sync.Mutex
	entries int
}

func (l *Ledger) Add() {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.entries++
}

func report(l *Ledger) { fmt.Println(l.entries) }

func main() {
	var l Ledger
	l.Add()
	report(&l)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet main.go'
go vet main.go 2>&1
echo "exit status $?"

say 'go vet pointers.go'
go vet pointers.go 2>&1
echo "exit status $?"
