#!/usr/bin/env bash
# go vet's copylocks analyzer: a struct that holds a sync.Mutex must not be
# copied, because the copy has its own lock state and guards nothing. The
# bad file copies an Account three ways; the good file uses pointers.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
mkdir "$dir/bad" "$dir/good"

cat >"$dir/bad/account.go" <<'GO'
package main

import (
	"fmt"
	"sync"
)

type Account struct {
	mu    sync.Mutex
	cents int64
}

// Balance has a value receiver: every call locks a copy of the mutex.
func (a Account) Balance() int64 {
	a.mu.Lock()
	defer a.mu.Unlock()
	return a.cents
}

func snapshot(a Account) Account { return a }

func main() {
	var savings Account
	backup := savings
	fmt.Println(savings.Balance(), snapshot(savings), backup.cents)
}
GO

cat >"$dir/good/account.go" <<'GO'
package main

import (
	"fmt"
	"sync"
)

type Account struct {
	mu    sync.Mutex
	cents int64
}

// Balance has a pointer receiver: the one mutex is locked.
func (a *Account) Balance() int64 {
	a.mu.Lock()
	defer a.mu.Unlock()
	return a.cents
}

// snapshot copies the number, not the struct that holds the lock.
func snapshot(a *Account) int64 { return a.Balance() }

func main() {
	savings := &Account{}
	fmt.Println(savings.Balance(), snapshot(savings))
}
GO

say() { printf '$ %s\n' "$*"; }

for pkg in bad good; do
	say "cd $pkg && go mod init example && go vet ."
	(cd "$dir/$pkg" && go mod init example >/dev/null 2>&1 && go vet . 2>&1)
	echo "exit status $?"
done
