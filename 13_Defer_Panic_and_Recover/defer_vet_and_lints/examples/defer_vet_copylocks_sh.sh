#!/usr/bin/env bash
# copylocks: a method with a value receiver on a struct that holds a Mutex
# locks and defers the unlock of a copy. Every call gets its own copy, so the
# lock guards nothing. A pointer receiver is the version vet accepts.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/by_value.go" <<'GO'
package main

import (
	"fmt"
	"sync"
)

type Ledger struct {
	mu      sync.Mutex
	balance int
}

func (l Ledger) Post(cents int) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.balance += cents
}

func main() {
	var ledger Ledger
	ledger.Post(1999)
	fmt.Println(ledger.balance)
}
GO

cat >"$dir/by_pointer.go" <<'GO'
package main

import (
	"fmt"
	"sync"
)

type Ledger struct {
	mu      sync.Mutex
	balance int
}

func (l *Ledger) Post(cents int) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.balance += cents
}

func main() {
	var ledger Ledger
	ledger.Post(1999)
	fmt.Println(ledger.balance)
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go vet by_value.go'
go vet by_value.go 2>&1
echo "exit status $?"

say 'go vet by_pointer.go'
go vet by_pointer.go 2>&1
echo "exit status $?"
say 'go run by_pointer.go'
go run by_pointer.go
